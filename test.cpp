#include <iostream>

#ifdef _WIN32
#include <fxc/fxc>
#endif
#include <npl/npl>
#include <cvl/cvl>
#include <osl/lcs>

#include "gtest/gtest.h"

int main(int argc, char *argv[]) {
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
    //todo: merge everything below in gtest
    auto arguments = osl::GetArgumentsVector(argc, argv);
    osl::log::setLogLevel(osl::log::info);
    osl::log::setLogSink<std::string>(
        [](int level, int key, auto log) {
            std::cout << log << std::endl;
        });
    osl::log::setLogSink<std::wstring>(
        [](int level, int key, auto log) {
            std::wcout << log << std::endl;
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
        std::cout << "test npl ftp <host> <port> <user> <pass>" << std::endl;
    }
    return 0;
}

#if defined(ENABLE_GTEST)

struct DispatcherFixture : public testing::Test {
    protected:
    std::shared_ptr<npl::dispatcher> d;
    void SetUp() override {
        #ifdef _WIN32
        WSADATA wsaData;
        auto rc = WSAStartup(MAKEWORD(2, 2), &wsaData);
        ASSERT_EQ(0, rc);
        #endif
        // dispatcher needs to be a shared pointer
        // for the subsequent weak_from_this to work
        d = singleton<npl::dispatcher>::getInstance();
        d->initialize_control();
    }
    void TearDown() override {
        singleton<npl::dispatcher>::destroy();
        #ifdef _WIN32
        auto rc = WSACleanup();
        ASSERT_EQ(0, rc);
        #endif
    }
};

TEST_F(DispatcherFixture, Construction) {
    while (!d->has_control_initialized()) {}
    ASSERT_EQ(d->has_control_initialized(), true);
}

#endif