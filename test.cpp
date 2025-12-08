#include <iostream>

#ifdef _WIN32
#include <fxc/fxc>
#endif
#include <npl/npl>
#include <cvl/cvl>
#include <osl/lcs>

void show_usage(void);

int main(int argc, char *argv[]) {
    auto arguments = osl::GetArgumentsVector(argc, argv);
    if (!arguments.size()) {
        show_usage();
        return 0;
    }
    osl::log::setLogLevel(osl::log::info);
    osl::log::setLogSink<std::string>(
        [](int level, int key, auto log) {
            std::cout << log << std::endl;
        });
    npl::initialize_dispatcher();
    auto ns = arguments[0];
    #ifdef _WIN32
    if (ns == "fxc") {
        fxc::entry(arguments);
    } else
    #endif
    if (ns == "npl") {
        npl::entry(arguments);
    } else if (ns == "cvl") {
        cvl::entry(arguments);
    } else if (ns == "osl") {
       osl::lcs_tests();
    } else {
        show_usage();
    }
    return 0;
}

void show_usage(void) {
    std::cout << "test npl ftp <host> <port> <user> <pass>" << std::endl;
}