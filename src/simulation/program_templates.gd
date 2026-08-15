class_name ProgramTemplates
extends RefCounted

const COLUMN_FIRST: String = """# Default: column-first access on row-major A
register sum = 0
register value = 0

for col in 0..4
    for row in 0..4
        load value, A[row][col]
        add sum, value
    end
end

store result, sum
"""

const ROW_FIRST: String = """# Optimized: row-first access on row-major A
register sum = 0
register value = 0

for row in 0..4
    for col in 0..4
        load value, A[row][col]
        add sum, value
    end
end

store result, sum
"""

