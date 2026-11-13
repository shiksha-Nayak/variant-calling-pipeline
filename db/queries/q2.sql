SELECT
    rs.run_id,
    rs.condition
FROM run_samples AS rs
WHERE rs.sample_id = 'NA12878'
ORDER BY rs.run_id;
