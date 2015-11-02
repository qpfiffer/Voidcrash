#include <math.h>

float d_sqrt(float number)
{
    int i;
    float x, y;
    x = number * 0.5;
    y  = number;
    i  = * (int * ) &y;
    i  = 0x5f3759df - (i >> 1);
    y  = * ( float * ) &i;
    y  = y * (1.5 - (x * y * y));
    y  = y * (1.5 - (x * y * y));
    return number * y;
}

float f_length2f(float *vec)
{
	return d_sqrt(vec[0] * vec[0] + vec[1] * vec[1]);
}

float f_distance2f(float *a, float *b)
{
	float tmp[2];
	tmp[0] = a[0] - b[0];
	tmp[1] = a[1] - b[1];
	return d_sqrt(tmp[0] * tmp[0] + tmp[1] * tmp[1]);
}

float f_dot2f(float *a, float *b)
{
	return a[0] * b[0] + a[1] * b[1];
}

void f_normalize2f(float *vec)
{
	float f;
	f = d_sqrt(vec[0] * vec[0] + vec[1] * vec[1]);
	vec[0] /= f;
	vec[1] /= f;
}

void f_reflect2f(float *output, float *pos, float *normal)
{
	float f;
	f = pos[0] * normal[0] + pos[1] * normal[1];
	output[0] = pos[0] - normal[0] * 2.0 * f;
	output[1] = pos[1] - normal[1] * 2.0 * f;
}

void f_flatten2f(float *output, float *pos, float *normal)
{
	float f;
	f = pos[0] * normal[0] + pos[1] * normal[1];
	output[0] = pos[0] - normal[0] * f;
	output[1] = pos[1] - normal[1] * f;
}

void f_project2f(float *output, float *plane_pos, float *normal, float *pos, float *vector)
{
	float f;
	f = normal[0] * (plane_pos[0] - pos[0]) + normal[1] * (plane_pos[1] - pos[1]);
	f /= normal[0] * vector[0] + normal[1] * vector[1];
	output[0] = pos[0] + vector[0] * f;
	output[1] = pos[1] + vector[1] * f;
}

/*---------------------------------------------------*/

float f_length3f(float *vec)
{
	return d_sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
}

float f_distance3f(float *a, float *b)
{
	float tmp[3];
	tmp[0] = a[0] - b[0];
	tmp[1] = a[1] - b[1];
	tmp[2] = a[2] - b[2];
	return d_sqrt(tmp[0] * tmp[0] + tmp[1] * tmp[1] + tmp[2] * tmp[2]);
}

float f_dot3f(float *a, float *b)
{
	return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

void f_cross3f(float *output, float *a, float *b)
{
	output[0] = a[1] * b[2] - a[2] * b[1];
	output[1] = a[2] * b[0] - a[0] * b[2];
	output[2] = a[0] * b[1] - a[1] * b[0];
}

void f_normalize3f(float *vec)
{
	float f;
	f = d_sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
	vec[0] /= f;
	vec[1] /= f;
	vec[2] /= f;
}


void f_normalize4f(float *vec)
{
	float f;
	f = d_sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2] + vec[3] * vec[3]);
	vec[0] /= f;
	vec[1] /= f;
	vec[2] /= f;
	vec[3] /= f;
}

void f_reflect3f(float *output, float *pos, float *normal)
{
	float f;
	f = pos[0] * normal[0] + pos[1] * normal[1] + pos[2] * normal[2];
	output[0] = pos[0] - normal[0] * 2.0 * f;
	output[1] = pos[1] - normal[1] * 2.0 * f;
	output[2] = pos[2] - normal[2] * 2.0 * f;
}

void f_flatten3f(float *output, float *pos, float *normal)
{
	float f;
	f = pos[0] * normal[0] + pos[1] * normal[1] + pos[2] * normal[2];
	output[0] = pos[0] - normal[0] * f;
	output[1] = pos[1] - normal[1] * f;
	output[2] = pos[2] - normal[2] * f;
}

void f_project3f(float *output, float *plane_pos, float *normal, float *pos, float *vector)
{
	float f;
	f = normal[0] * (plane_pos[0] - pos[0]) + normal[1] * (plane_pos[1] - pos[1]) + normal[2] * (plane_pos[2] - pos[2]);
	f /= normal[0] * vector[0] + normal[1] * vector[1] + normal[2] * vector[2];
	output[0] = pos[0] + vector[0] * f;
	output[1] = pos[1] + vector[1] * f;
    output[2] = pos[2] + vector[2] * f;
}

void f_intersect2f(float *output, float *line_a0, float *line_a1, float *line_b0, float *line_b1)
{
	output[0] = (line_a0[0] * line_a1[1] - line_a0[1] * line_a1[0])	* (line_b0[0] - line_b1[0]) - 
				(line_b0[0] * line_b1[1] - line_b0[1] * line_b1[0])	* (line_a0[0] - line_a1[0]);
	output[0] /= (line_a0[0] - line_a1[0]) * (line_b0[1] - line_b1[1]) - (line_a0[1] - line_a1[1]) * (line_b0[0] - line_b1[0]);
	output[1] = (line_a0[0] * line_a1[1] - line_a0[1] * line_a1[0])	* (line_b0[1] - line_b1[1]) - 
				(line_b0[0] * line_b1[1] - line_b0[1] * line_b1[0])	* (line_a0[1] - line_a1[1]);
	output[1] /= (line_a0[0] - line_a1[0]) * (line_b0[1] - line_b1[1]) - (line_a0[1] - line_a1[1]) * (line_b0[0] - line_b1[0]);
}



double f_length2d(double *vec)
{
	return sqrt(vec[0] * vec[0] + vec[1] * vec[1]);
}

double f_distance2d(double *a, double *b)
{
	double tmp[2];
	tmp[0] = a[0] - b[0];
	tmp[1] = a[1] - b[1];
	return sqrt(tmp[0] * tmp[0] + tmp[1] * tmp[1]);
}

double f_dot2d(double *a, double *b)
{
	return a[0] * b[0] + a[1] * b[1];
}

void f_normalize2d(double *vec)
{
	double f;
	f = sqrt(vec[0] * vec[0] + vec[1] * vec[1]);
	vec[0] /= f;
	vec[1] /= f;
}

void f_reflect2d(double *output, double *pos, double *normal)
{
	double f;
	f = pos[0] * normal[0] + pos[1] * normal[1];
	output[0] = pos[0] - normal[0] * 2.0 * f;
	output[1] = pos[1] - normal[1] * 2.0 * f;
}

void f_flatten2d(double *output, double *pos, double *normal)
{
	double f;
	f = pos[0] * normal[0] + pos[1] * normal[1];
	output[0] = pos[0] - normal[0] * f;
	output[1] = pos[1] - normal[1] * f;
}

void f_project2d(double *output, double *plane_pos, double *normal, double *pos, double *vector)
{
	double f;
	f = normal[0] * (plane_pos[0] - pos[0]) + normal[1] * (plane_pos[1] - pos[1]);
	f /= normal[0] * vector[0] + normal[1] * vector[1];
	output[0] = pos[0] + vector[0] * f;
	output[1] = pos[1] + vector[1] * f;
}

void f_intersect2d(double *output, double *line_a0, double *line_a1, double *line_b0, double *line_b1)
{
	output[0] = (line_a0[0] * line_a1[1] - line_a0[1] * line_a1[0])	* (line_b0[0] - line_b1[0]) - 
				(line_b0[0] * line_b1[1] - line_b0[1] * line_b1[0])	* (line_a0[0] - line_a1[0]);
	output[0] /= (line_a0[0] - line_a1[0]) * (line_b0[1] - line_b1[1]) - (line_a0[1] - line_a1[1]) * (line_b0[0] - line_b1[0]);
	output[1] = (line_a0[0] * line_a1[1] - line_a0[1] * line_a1[0])	* (line_b0[1] - line_b1[1]) - 
				(line_b0[0] * line_b1[1] - line_b0[1] * line_b1[0])	* (line_a0[1] - line_a1[1]);
	output[1] /= (line_a0[0] - line_a1[0]) * (line_b0[1] - line_b1[1]) - (line_a0[1] - line_a1[1]) * (line_b0[0] - line_b1[0]);
}
/*---------------------------------------------------*/

double f_length3d(double *vec)
{
	return sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
}

double f_distance3d(double *a, double *b)
{
	double tmp[3];
	tmp[0] = a[0] - b[0];
	tmp[1] = a[1] - b[1];
	tmp[2] = a[2] - b[2];
	return sqrt(tmp[0] * tmp[0] + tmp[1] * tmp[1] + tmp[2] * tmp[2]);
}

double f_dot3d(double *a, double *b)
{
	return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

void f_cross3d(double *output, double *a, double *b)
{
	output[0] = a[1] * b[2] - a[2] * b[1];
	output[1] = a[2] * b[0] - a[0] * b[2];
	output[2] = a[0] * b[1] - a[1] * b[0];
}

void f_normalize3d(double *vec)
{
	double f;
	f = sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
	vec[0] /= f;
	vec[1] /= f;
	vec[2] /= f;
}

void f_normalize4d(double *vec)
{
	double f;
	f = sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2] + vec[3] * vec[3]);
	vec[0] /= f;
	vec[1] /= f;
	vec[2] /= f;
	vec[3] /= f;
}

void f_reflect3d(double *output, double *pos, double *normal)
{
	double f;
	f = pos[0] * normal[0] + pos[1] * normal[1] + pos[2] * normal[2];
	output[0] = pos[0] - normal[0] * 2.0 * f;
	output[1] = pos[1] - normal[1] * 2.0 * f;
	output[2] = pos[2] - normal[2] * 2.0 * f;
}

void f_flatten3d(double *output, double *pos, double *normal)
{
	double f;
	f = pos[0] * normal[0] + pos[1] * normal[1] + pos[2] * normal[2];
	output[0] = pos[0] - normal[0] * f;
	output[1] = pos[1] - normal[1] * f;
	output[2] = pos[2] - normal[2] * f;
}

void f_project3d(double *output, double *plane_pos, double *normal, double *pos, double *vector)
{
	double f;
	f = normal[0] * (plane_pos[0] - pos[0]) + normal[1] * (plane_pos[1] - pos[1]) + normal[2] * (plane_pos[2] - pos[2]);
	f /= normal[0] * vector[0] + normal[1] * vector[1] + normal[2] * vector[2];
	output[0] = pos[0] + vector[0] * f;
	output[1] = pos[1] + vector[1] * f;
    output[2] = pos[2] + vector[2] * f;
}

/*---------------------------------------------------*/


#define f_sqrt_step(shift) \
    if((0x40000000l >> shift) + root <= value)          \
    {                                                   \
        value -= (0x40000000l >> shift) + root;         \
        root = (root >> 1) | (0x40000000l >> shift);    \
    }                                                   \
    else                                                \
    {                                                   \
        root = root >> 1;                               \
    }

long f_sqrti(long value)
{
    long root = 0;
    f_sqrt_step( 0);
    f_sqrt_step( 2);
    f_sqrt_step( 4);
    f_sqrt_step( 6);
    f_sqrt_step( 8);
    f_sqrt_step(10);
    f_sqrt_step(12);
    f_sqrt_step(14);
    f_sqrt_step(16);
    f_sqrt_step(18);
    f_sqrt_step(20);
    f_sqrt_step(22);
    f_sqrt_step(24);
    f_sqrt_step(26);
    f_sqrt_step(28);
    f_sqrt_step(30);
    if(root < value)
        ++root;
    return root;
}

unsigned char f_normalize_2di(int *point, int fixed_point_multiplyer)
{
	int length;
	length = f_sqrti(point[0] * point[0] + point[1] * point[1]);
	if(length != 0)
	{
		point[0] = (point[0] * fixed_point_multiplyer) / length;
		point[1] = (point[1] * fixed_point_multiplyer) / length;
		return 1;
	}
	return 0;
}

unsigned char f_normalize_3di(int *point, int fixed_point_multiplyer)
{
	int length;
	length = f_sqrti(point[0] * point[0] + point[1] * point[1] + point[2] * point[2]);
	if(length != 0)
	{
		point[0] = (point[0] * fixed_point_multiplyer) / length;
		point[1] = (point[1] * fixed_point_multiplyer) / length;
		point[2] = (point[2] * fixed_point_multiplyer) / length;
		return 1;
	}
	return 0;
}


void f_intersect2di(int *output, int *line_a0, int *line_a1, int *line_b0, int *line_b1)
{
	output[0] = (line_a0[0] * line_a1[1] - line_a0[1] * line_a1[0])	* (line_b0[0] - line_b1[0]) - 
				(line_b0[0] * line_b1[1] - line_b0[1] * line_b1[0])	* (line_a0[0] - line_a1[0]);
	output[0] /= (line_a0[0] - line_a1[0]) * (line_b0[1] - line_b1[1]) - (line_a0[1] - line_a1[1]) * (line_b0[0] - line_b1[0]);
	output[1] = (line_a0[0] * line_a1[1] - line_a0[1] * line_a1[0])	* (line_b0[1] - line_b1[1]) - 
				(line_b0[0] * line_b1[1] - line_b0[1] * line_b1[0])	* (line_a0[1] - line_a1[1]);
	output[1] /= (line_a0[0] - line_a1[0]) * (line_b0[1] - line_b1[1]) - (line_a0[1] - line_a1[1]) * (line_b0[0] - line_b1[0]);
}
