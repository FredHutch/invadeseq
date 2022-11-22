process validate_manifest {
    container "${params.container__python}"
    label "io_limited"

    input:
    path manifest

    output:
    path "${manifest}"

    """#!/usr/bin/env python3
import pandas as pd

print("Reading in ${manifest.name} as CSV")
df = pd.read_csv("${manifest.name}")
print(f"Read in {df.shape[0]:,} rows")

required_columns = ['sample', 'gex', 'microbial']
msg = "Manifest must contain columns: {', '.join(required_columns)}"
for cname in required_columns:
    assert cname in df.columns.values, f"{msg}: Missing '{cname}'"

print("Looks good!")
    """
}