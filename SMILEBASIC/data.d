module otya.smilebasic.data;

enum DataType : byte
{
    ushort_ = 3,
    int_ = 4,
    double_ = 5
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
