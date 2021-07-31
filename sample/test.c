extern void * _heap;

void main() {

    /* Calculate pi * r * r for very large circles.. */
    float pi=3.1415926;
    long value;
    for(long i=1001000;i<2000000;i+=100000)
        value=i * i * pi;
    
    /* Cast value to unsigned char and write to heap */
    unsigned char *vmem=(unsigned char *)&_heap;
    *vmem=(unsigned char)value;
    
}