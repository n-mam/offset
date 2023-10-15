#ifndef QUEUE_HPP
#define QUEUE_HPP

#include <mutex>
#include <array>

#include <opencv2/core.hpp>

namespace cvl {

template <typename T, int N = 50>
class queue
{
  public:

  queue(){}

  ~queue(){}

  auto enqueue(T& frame)
  {
    std::lock_guard<std::mutex> lg(_mux);

    _queue[_write_index % _queue.max_size()] = frame;

    _write_index = (_write_index + 1) % _queue.max_size();
  }

  auto dequeue()
  {
    std::lock_guard<std::mutex> lg(_mux);

    auto& e = _queue[_read_index % _queue.max_size()];

    if (!e.empty())
    {
      _read_index = (_read_index + 1) % _queue.max_size();
    }

    auto clone = e.clone();

    e = T();

    return clone;
  }

  private:

  std::mutex _mux;

  int _read_index = 0;

  int _write_index = 0;

  std::array<T, N> _queue;
};

}

#endif