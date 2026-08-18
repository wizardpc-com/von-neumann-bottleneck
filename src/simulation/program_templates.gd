class_name ProgramTemplates
extends RefCounted

const COLUMN_FIRST: String = """# Starter: column-first access on row-major A
acc = 0
for col in range(4):
    for row in range(4):
        acc += load(A[row][col])
store(OUT[0], acc)
"""

const ROW_FIRST: String = """# Test fixture: row-first access on row-major A
acc = 0
for row in range(4):
    for col in range(4):
        acc += load(A[row][col])
store(OUT[0], acc)
"""

