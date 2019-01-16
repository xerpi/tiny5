#define ARRAY_LEN(x) (sizeof(x) / sizeof(*x))

#define N 8

int a[N][N], b[N][N], c[N][N];

void main()
{
	int i, j, k, sum;

	/* Fill matrices */
	for (i = 0; i < N; i++) {
		for(j = 0; j < N; j++) {
			a[i][j] = i + j + 1;
			b[i][j] = (N - (i + 1)) * (j + 1);
		}
	}

	/* Matrix multiplication */
	for (i = 0; i < N; i++) {
		for(j = 0; j < N; j++) {
			c[i][j] = 0;
			for(k = 0; k < N; k++)
				c[i][j] = c[i][j] + a[i][k] * b[k][j];
		}
	}

	/* Check result (sum should be 52416) */
	sum = 0;
	for (i = 0; i < N; i++) {
		for(j = 0; j < N; j++)
			sum += c[i][j];
	}

	/* Test done: ECALL, result to r3 */
	asm volatile(
		"add x3, %0, x0\n\t"
		"ecall"
		: : "r"(sum)
	);
}
