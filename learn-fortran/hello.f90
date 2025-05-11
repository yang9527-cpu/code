program example
    implicit none
    integer::a=2,b=3
    integer,external::add
    !声明add是一个函数
    write(*,*)add(a,b)
end
function add(first,second)
    implicit none
    integer::first,second
    integer::add
    !add跟函数名称一样，这里不是用来声明变量
    !这里是声明这个函数会返回的数值类型
    add=first+second
    return 
end