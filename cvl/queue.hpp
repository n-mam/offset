
#ifndef QUEUE_HPP
#define QUEUE_HPP

#include <mutex>
#include <array>
#include <cstddef>
#include <stdexcept>
#include <utility>

namespace cvl {

template <typename T, std::size_t N = 50>
struct queue {

    static_assert(N > 0, "Queue capacity must be greater than zero");

    queue() = default;
    queue(const queue&) = delete;
    queue& operator=(const queue&) = delete;

    void enqueue(const T& value) {
        std::lock_guard<std::mutex> lock(_mux);
        _queue[_write_index] = value;
        _write_index = (_write_index + 1) % N;
        if (_count == N) {
            _read_index = (_read_index + 1) % N;
        } else {
            ++_count;
        }
    }

    T dequeue() {
        std::lock_guard<std::mutex> lock(_mux);
        if (_count == 0) {
            return T{};
        }
        T result = std::move(_queue[_read_index]);
        _read_index = (_read_index + 1) % N;
        --_count;
        return result;
    }

    void clear() {
        std::lock_guard<std::mutex> lock(_mux);
        _read_index = 0;
        _write_index = 0;
        _count = 0;
        _queue.fill(T{});
    }

    std::size_t size() const {
        std::lock_guard<std::mutex> lock(_mux);
        return _count;
    }

    constexpr std::size_t capacity() const {
        return N;
    }

    bool empty() const {
        std::lock_guard<std::mutex> lock(_mux);
        return _count == 0;
    }

    bool full() const {
        std::lock_guard<std::mutex> lock(_mux);
        return _count == N;
    }

    T front() const {
        std::lock_guard<std::mutex> lock(_mux);
        if (_count == 0) {
            return T{};
        }
        return _queue[_read_index];
    }

    T back() const {
        std::lock_guard<std::mutex> lock(_mux);
        if (_count == 0) {
            return T{};
        }
        const auto index = (_write_index + N - 1) % N;
        return _queue[index];
    }

    T operator[](std::size_t i) const {
        std::lock_guard<std::mutex> lock(_mux);
        if (i >= _count) {
            throw std::out_of_range("Queue index out of range");
        }
        return _queue[(_read_index + i) % N];
    }

    private:

    std::size_t _count = 0;
    mutable std::mutex _mux;
    std::size_t _read_index = 0;
    std::size_t _write_index = 0;
    std::array<T, N> _queue{};
};

}

#endif
