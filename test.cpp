#include <iostream>

#ifdef _WIN32
#include <fxc/fxc>
#endif

#include <npl/npl>

int main(int argc, char *argv[])
{
  auto arguments = osl::GetArgumentsVector(argc, argv);

  if (!arguments.size()) return 0;

  npl::make_dispatcher();

  osl::log::SetLogSink<std::string>(
    [](int key, auto log){
      std::cout << log << std::endl;
    }
  );

  osl::log::SetLogLevel(osl::log::info);

  auto ns = arguments[0];

  #ifdef _WIN32
  if (ns == "fxc")
    fxc::entry(arguments);
  #endif
  
  if (ns == "npl")
    npl::entry(arguments);

  return 0;
}
