#include <iostream>

#include <fxc/fxc>

int wmain(int argc, wchar_t *argv[])
{
  auto arguments = osl::GetArgumentsVector(argc, argv);

  if (!arguments.size())
  {
    fxc::usage();
    return 0;
  }

  osl::Log::SetLogSink<std::string>(
    [](auto level, auto log){
      if (level == 0) {
        std::cout << log << std::endl;
      }
    });

  npl::make_dispatcher();

  auto ns = arguments[0];

  if (ns == L"fxc")
  {
    fxc::entry(arguments);
  }
  else if (ns == L"npl")
  {
    npl::entry(arguments);
  }
  else
  {
    LOG << "unknown namespace";
  }

  return 0;
}
