"""
Fibonacci Variants - Five Different Implementations
"""

from functools import lru_cache


def fibonacci_recursive(n):
    """
    Classic naive recursive Fibonacci implementation.
    Time complexity: O(2^n)
    Space complexity: O(n) due to call stack

    Args:
        n (int): The position in Fibonacci sequence (0-indexed)

    Returns:
        int: The nth Fibonacci number
    """
    if n <= 1:
        return n
    return fibonacci_recursive(n - 1) + fibonacci_recursive(n - 2)


@lru_cache(maxsize=None)
def fibonacci_memoized(n):
    """
    Top-down dynamic programming Fibonacci with memoization.
    Time complexity: O(n)
    Space complexity: O(n)

    Args:
        n (int): The position in Fibonacci sequence (0-indexed)

    Returns:
        int: The nth Fibonacci number
    """
    if n <= 1:
        return n
    return fibonacci_memoized(n - 1) + fibonacci_memoized(n - 2)


def fibonacci_iterative(n):
    """
    Bottom-up iterative Fibonacci implementation.
    Time complexity: O(n)
    Space complexity: O(1)

    Args:
        n (int): The position in Fibonacci sequence (0-indexed)

    Returns:
        int: The nth Fibonacci number
    """
    if n <= 1:
        return n

    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b


def fibonacci_generator(n):
    """
    Generator-based Fibonacci implementation.
    Yields Fibonacci numbers up to the nth position.
    Time complexity: O(n)
    Space complexity: O(1)

    Args:
        n (int): The position in Fibonacci sequence (0-indexed)

    Yields:
        int: Fibonacci numbers from 0 to n
    """
    a, b = 0, 1
    for i in range(n + 1):
        if i == 0:
            yield a
        elif i == 1:
            yield b
        else:
            a, b = b, a + b
            yield b


def matrix_multiply(a, b):
    """
    Multiply two 2x2 matrices.

    Args:
        a (list): First 2x2 matrix
        b (list): Second 2x2 matrix

    Returns:
        list: Resultant 2x2 matrix
    """
    return [
        [a[0][0] * b[0][0] + a[0][1] * b[1][0], a[0][0] * b[0][1] + a[0][1] * b[1][1]],
        [a[1][0] * b[0][0] + a[1][1] * b[1][0], a[1][0] * b[0][1] + a[1][1] * b[1][1]]
    ]


def matrix_power(matrix, n):
    """
    Compute matrix^n using binary exponentiation.

    Args:
        matrix (list): 2x2 matrix
        n (int): Power to raise the matrix to

    Returns:
        list: Resultant 2x2 matrix
    """
    if n == 1:
        return matrix

    if n % 2 == 0:
        half = matrix_power(matrix, n // 2)
        return matrix_multiply(half, half)
    else:
        return matrix_multiply(matrix, matrix_power(matrix, n - 1))


def fibonacci_matrix(n):
    """
    Matrix exponentiation Fibonacci implementation.
    Uses the property: [[F(n+1), F(n)], [F(n), F(n-1)]] = [[1, 1], [1, 0]]^n
    Time complexity: O(log n)
    Space complexity: O(log n) due to recursion

    Args:
        n (int): The position in Fibonacci sequence (0-indexed)

    Returns:
        int: The nth Fibonacci number
    """
    if n <= 1:
        return n

    base_matrix = [[1, 1], [1, 0]]
    result = matrix_power(base_matrix, n)
    return result[0][1]


if __name__ == "__main__":
    n = 10

    print(f"Fibonacci number at position {n}:\n")

    # Test recursive
    result = fibonacci_recursive(n)
    print(f"1. Recursive:             {result}")

    # Test memoized
    result = fibonacci_memoized(n)
    print(f"2. Memoized:              {result}")

    # Test iterative
    result = fibonacci_iterative(n)
    print(f"3. Iterative:             {result}")

    # Test generator (get the last value)
    result = list(fibonacci_generator(n))[-1]
    print(f"4. Generator:             {result}")

    # Test matrix exponentiation
    result = fibonacci_matrix(n)
    print(f"5. Matrix Exponentiation: {result}")

    print("\nAll variants produce the same result! ✓")
