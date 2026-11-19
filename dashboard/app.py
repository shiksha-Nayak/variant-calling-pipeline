import os
import sys
import sqlite3
from urllib.parse import parse_qs

import pandas as pd
import plotly.express as px

from dash import Dash, dcc, html, Input, Output, State, ctx
import dash_ag_grid as dag


# Database path and port
DB_PATH = os.path.abspath(sys.argv[1])
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8050

here = os.path.dirname(os.path.abspath(__file__))


def get_connection():
    return sqlite3.connect(DB_PATH)


def get_runs():
    query_path = os.path.join(here, "..", "db", "queries", "q1.sql")

    with open(query_path) as f:
        query = f.read()

    with get_connection() as con:
        return pd.read_sql_query(query, con)


def get_samples(run_id):
    query = """
        SELECT
            rs.sample_id,
            rs.condition,
            COALESCE(s.phenotype, '') AS phenotype,
            COALESCE(s.is_synthetic_phenotype, '') AS is_synthetic_phenotype
        FROM run_samples AS rs
        LEFT JOIN samples AS s
            ON rs.sample_id = s.sample_id
        WHERE rs.run_id = ?
        ORDER BY rs.sample_id
    """

    with get_connection() as con:
        return pd.read_sql_query(query, con, params=(run_id,))


def get_variants(run_id):
    query = """
        SELECT chrom, pos, ref, alt, qual, "filter"
        FROM variants
        WHERE run_id = ?
        ORDER BY chrom, pos
    """

    with get_connection() as con:
        return pd.read_sql_query(query, con, params=(run_id,))


def classify_variants(df):
    df = df.copy()

    def get_variant_type(row):
        ref = str(row["ref"])
        alt = str(row["alt"])

        if "," in alt:
            return "multiallelic"
        elif len(ref) == 1 and len(alt) == 1:
            return "SNP"
        else:
            return "indel"

    def get_titv(row):
        ref = str(row["ref"]).upper()
        alt = str(row["alt"]).upper()

        if (ref, alt) in [("A", "G"), ("G", "A"),
                          ("C", "T"), ("T", "C")]:
            return "transition"

        return "transversion"

    df["variant_type"] = df.apply(get_variant_type, axis=1)

    df["titv"] = ""
    snp_mask = df["variant_type"] == "SNP"
    df.loc[snp_mask, "titv"] = df.loc[snp_mask].apply(
        get_titv, axis=1
    )

    return df


def make_grid(grid_id, df):
    return dag.AgGrid(
        id=grid_id,
        rowData=df.to_dict("records"),
        columnDefs=[{"field": c} for c in df.columns],
        columnSize="sizeToFit"
    )


def make_runs_page():
    runs = get_runs()

    links = [
        html.Div(
            dcc.Link(
                f"View results: {row['run_id']}",
                href=f"/results?run={row['run_id']}"
            ),
            style={"marginBottom": "8px"}
        )
        for _, row in runs.iterrows()
    ]

    return html.Div([
        html.H1("Variant Calling Pipeline Results"),
        html.H2("Runs"),
        html.Div(links),
        make_grid("runs-table", runs)
    ], style={"padding": "25px"})


def make_results_page(run_id):
    samples = get_samples(run_id)
    variants = get_variants(run_id)
    classified = classify_variants(variants)

    # Plot 1: Count of sites per exact filter value
    filter_counts = (
        classified["filter"]
        .fillna("")
        .value_counts()
        .rename_axis("filter")
        .reset_index(name="count")
    )

    filter_fig = px.bar(
        filter_counts,
        x="filter",
        y="count",
        title="Count of Sites per Filter Value",
        labels={"filter": "Filter", "count": "Number of Sites"}
    )

    # Plot 2: SNP, indel, and multiallelic counts
    type_counts = (
        classified["variant_type"]
        .value_counts()
        .reindex(["SNP", "indel", "multiallelic"], fill_value=0)
        .rename_axis("variant_type")
        .reset_index(name="count")
    )

    type_fig = px.bar(
        type_counts,
        x="variant_type",
        y="count",
        title="Counts of SNPs, Indels, and Multiallelic Sites",
        labels={
            "variant_type": "Variant Type",
            "count": "Number of Sites"
        }
    )

    # Plot 3: Transitions and transversions among SNPs only
    snps = classified[classified["variant_type"] == "SNP"]

    titv_counts = (
        snps["titv"]
        .value_counts()
        .reindex(["transition", "transversion"], fill_value=0)
        .rename_axis("titv")
        .reset_index(name="count")
    )

    titv_fig = px.bar(
        titv_counts,
        x="titv",
        y="count",
        title="Transitions and Transversions Among SNPs",
        labels={"titv": "SNP Substitution Type", "count": "Number of SNPs"}
    )

    return html.Div([
        html.H1(f"Results for Run: {run_id}"),
        dcc.Link("Back to Runs", href="/"),
        html.H2("Samples"),
        html.P(
            "Phenotype values marked as synthetic are made up "
            "for demonstration purposes."
        ),
        make_grid("samples-table", samples),

        html.H2("Variant Plots"),
        dcc.Graph(id="plot-filter", figure=filter_fig),
        dcc.Graph(id="plot-type", figure=type_fig),
        dcc.Graph(id="plot-titv", figure=titv_fig),

        html.H2("Variant Sites"),
        html.P("Click a bar above to filter the sites table."),
        make_grid("sites-table", variants)
    ], style={"padding": "25px"})


app = Dash(__name__, suppress_callback_exceptions=True)

app.layout = html.Div([
    dcc.Location(id="url", refresh=False),
    html.Div(id="page-content")
])


@app.callback(
    Output("page-content", "children"),
    Input("url", "pathname"),
    Input("url", "search")
)
def display_page(pathname, search):
    if pathname == "/results":
        parameters = parse_qs(search.lstrip("?"))
        run_ids = parameters.get("run", [])

        if not run_ids:
            return html.Div([
                html.H2("No run selected"),
                dcc.Link("Back to Runs", href="/")
            ])

        return make_results_page(run_ids[0])

    return make_runs_page()


@app.callback(
    Output("sites-table", "rowData"),
    Input("plot-filter", "clickData"),
    Input("plot-type", "clickData"),
    Input("plot-titv", "clickData"),
    State("url", "search")
)
def filter_sites(filter_click, type_click, titv_click, search):
    parameters = parse_qs(search.lstrip("?"))
    run_ids = parameters.get("run", [])

    if not run_ids:
        return []

    run_id = run_ids[0]
    triggered = ctx.triggered_id

    variants = get_variants(run_id)

    if triggered is None:
        return variants.to_dict("records")

    if triggered == "plot-filter":
        click_data = filter_click
    elif triggered == "plot-type":
        click_data = type_click
    else:
        click_data = titv_click

    if not click_data or not click_data.get("points"):
        return variants.to_dict("records")

    selected = click_data["points"][0].get("x")

    if selected is None:
        return variants.to_dict("records")

    classified = classify_variants(variants)

    if triggered == "plot-filter":
        filtered = classified[
            classified["filter"].fillna("") == selected
        ]
    elif triggered == "plot-type":
        filtered = classified[
            classified["variant_type"] == selected
        ]
    else:
        filtered = classified[
            classified["titv"] == selected
        ]

    # Return only the original variant columns
    return filtered[
        ["chrom", "pos", "ref", "alt", "qual", "filter"]
    ].to_dict("records")


if __name__ == "__main__":
    app.run(port=PORT, debug=True)
