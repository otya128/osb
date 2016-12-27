module otya.smilebasic.data;

enum DataType : byte
{
    ushort_,
    int_,
    double_
}

align(1) struct DataHeader
{
    char[8] magic;//PCBN0001
    DataType type;
    byte dimension;
    int dim1;
    int dim2;
    int dim3;
    int dim4;
}
