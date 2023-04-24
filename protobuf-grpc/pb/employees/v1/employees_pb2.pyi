from google.api import annotations_pb2 as _annotations_pb2
from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Iterable as _Iterable, Mapping as _Mapping, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class GetEmployeeRequest(_message.Message):
    __slots__ = ["short_name"]
    SHORT_NAME_FIELD_NUMBER: _ClassVar[int]
    short_name: str
    def __init__(self, short_name: _Optional[str] = ...) -> None: ...

class GetEmployeeResponse(_message.Message):
    __slots__ = ["employee"]
    class Employee(_message.Message):
        __slots__ = ["birthday", "full_name", "id"]
        BIRTHDAY_FIELD_NUMBER: _ClassVar[int]
        FULL_NAME_FIELD_NUMBER: _ClassVar[int]
        ID_FIELD_NUMBER: _ClassVar[int]
        birthday: str
        full_name: str
        id: int
        def __init__(self, id: _Optional[int] = ..., full_name: _Optional[str] = ..., birthday: _Optional[str] = ...) -> None: ...
    EMPLOYEE_FIELD_NUMBER: _ClassVar[int]
    employee: GetEmployeeResponse.Employee
    def __init__(self, employee: _Optional[_Union[GetEmployeeResponse.Employee, _Mapping]] = ...) -> None: ...

class ListEmployeesRequest(_message.Message):
    __slots__ = []
    def __init__(self) -> None: ...

class ListEmployeesResponse(_message.Message):
    __slots__ = ["short_names"]
    SHORT_NAMES_FIELD_NUMBER: _ClassVar[int]
    short_names: _containers.RepeatedScalarFieldContainer[str]
    def __init__(self, short_names: _Optional[_Iterable[str]] = ...) -> None: ...
