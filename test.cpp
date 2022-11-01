#include <iostream>

#include <npl/npl>
#include <osl/osl>

#include <fxc/fxc>

int wmain(int argc, wchar_t *argv[])
{
  auto arguments = osl::GetArgumentsVector(argc, argv);

  if (!arguments.size())
  {
    fxc::usage();
    return 0;
  }

  auto ns = arguments[0];

  if (ns == L"fxc")
  {
    fxc::entry(arguments);
  }
  else if (ns == L"npl")
  {

  }
  else
  {
    std::cout << "unknown namespace" << std::endl;
  }

  return 0;
}
