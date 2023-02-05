#include <iostream>

#ifdef _WIN32
#include <fxc/fxc>
#endif

#include <npl/npl>

#ifdef _WIN32
int wmain(int argc, wchar_t *argv[])
#else
int main(int argc, char *argv[])
#endif
{
  auto arguments = osl::GetArgumentsVector(argc, argv);

  if (!arguments.size())
    return 0;

  osl::log::SetLogSink<std::string>(
    [](auto level, int key, auto log){
      if (level >= 0) {
        std::cout << log << std::endl;
      }
    });

  npl::make_dispatcher();

  auto ns = arguments[0];

  if (ns == "fxc")
  {
    #ifdef _WIN32
    fxc::entry(arguments);
    #endif
  }
  else if (ns == "npl")
  {
    //npl::entry(arguments);
  }
  else
  {
    LOG << "unknown namespace";
  }

  return 0;
}
