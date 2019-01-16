#define ARRAY_LEN(x) (sizeof(x) / sizeof(*x))

#define N 2

int a[N][N], b[N][N], c[N][N];

void main()
{
	int i, j, k, ok = 1;

	for (i = 0; i < N; i++) {
		for(j = 0; j < N;j++) {
			c[i][j] = 0;
			for(k = 0; k < N; k++)
				c[i][j] = c[i][j] + a[i][k] * b[k][j];
		}
	}

	/* Test done: ECALL, result to r3 */
	asm volatile(
		"add x3, %0, x0\n\t"
		"ecall"
		: : "r"(ok)
	);
}
