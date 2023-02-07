#include <iostream>

#ifdef _WIN32
#include <fxc/fxc>
#endif

#include <npl/npl>

int main(int argc, char *argv[])
{
  auto arguments = osl::GetArgumentsVector(argc, argv);

  if (!arguments.size()) return 0;

  osl::log::SetLogSink<std::string>(
    [](auto level, int key, auto log){
      if (level >= 0) {
        std::cout << log << std::endl;
      }
    });

  npl::make_dispatcher();

  auto ns = arguments[0];

  #ifdef _WIN32
  if (ns == "fxc")
    fxc::entry(arguments);
  #endif
  
  if (ns == "npl")
    npl::entry(arguments);

  return 0;
}
