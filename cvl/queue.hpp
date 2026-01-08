#ifndef QUEUE_HPP
#define QUEUE_HPP

#include <mutex>
#include <array>

#include <opencv2/core.hpp>

namespace cvl {

template <typename T, int N = 50>
struct queue {

    queue() = default;
    ~queue(){}

    auto enqueue(const T& frame) {
        std::lock_guard<std::mutex> lg(_mux);
        _queue[_write_index % N] = frame;
        _write_index = (_write_index + 1) % N;
    }

    auto dequeue() {
        std::lock_guard<std::mutex> lg(_mux);
        auto& e = _queue[_read_index % N];
        if (!e.empty()) {
            _read_index = (_read_index + 1) % N;
        }
        auto clone = e.clone();
        e = T();
        return clone;
    }

    auto clear() {
        _read_index = 0;
        _write_index = 0;
        std::ranges::fill(_queue, T());
    }

    auto size() const {
        return N;
    }

    const T& latest() const {
        return _queue[_write_index];
    }

    const T& oldest() const {
        return _queue[_read_index];
    }

    const T& operator [](int i) const {
        return _queue[i];
    }

    private:

    std::mutex _mux;
    int _read_index = 0;
    int _write_index = 0;
    std::array<T, N> _queue;
};

}

#endif