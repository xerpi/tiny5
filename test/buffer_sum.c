#define ARRAY_LEN(x) (sizeof(x) / sizeof(*x))

int a[128] = {1};

void main()
{
	int i, sum = 0;

	for (i = 0; i < ARRAY_LEN(a); i++)
		a[i] = i;

	for (i = 0; i < ARRAY_LEN(a); i++)
		sum += a[i];

	/* Test done: ECALL, result to r3 */
	asm volatile(
		"add x3, %0, x0\n\t"
		"ecall"
		: : "r"(sum)
	);
}
