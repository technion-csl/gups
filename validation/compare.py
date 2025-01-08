#! /usr/bin/env python3

import sys
import pandas as pd
import numpy as np
from scipy import stats

df = pd.read_csv(sys.stdin, names=['our', 'ref'], header=None)
if len(df.columns) != 2:
    raise ValueError("CSV file must contain exactly two columns")

statistic, p_value = stats.mannwhitneyu(df['our'], df['ref'], alternative='two-sided')

print("The measurements are:")
print(df)
print(f"The two measurements are drawn from the same distribution with probability {p_value:.2f}")

