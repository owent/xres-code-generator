// Copyright 2024 xresloader

#pragma once

#include <atomic>
#include <chrono>
#include <thread>

#ifndef CONFIG_EXCEL_CONFIG_API_HEAD_ONLY
#  if defined(__GNUC__) && !defined(__ibmxl__)
//  GNU C++/Clang
//
// Dynamic shared object (DSO) and dynamic-link library (DLL) support
//
#    if (__GNUC__ >= 4) && !(defined(_WIN32) || defined(__WIN32__) || defined(WIN32) || defined(__CYGWIN__))
#      define CONFIG_EXCEL_CONFIG_API_HEAD_ONLY __attribute__((__visibility__("default")))
#    endif
#  endif

#  ifndef CONFIG_EXCEL_CONFIG_API_HEAD_ONLY
#    define CONFIG_EXCEL_CONFIG_API_HEAD_ONLY
#  endif

#endif

namespace excel {
namespace lock {
class CONFIG_EXCEL_CONFIG_API_HEAD_ONLY spin_rw_lock {
 private:
  std::atomic<int32_t> lock_status_;

  enum {
    WRITE_LOCK_FLAG = 0x01,
  };
  enum {
    MAX_READ_LOCK_HOLDER = INT32_MAX - 1,
  };

 public:
  spin_rw_lock() { lock_status_.store(0); }

  void read_lock() {
    unsigned char try_times = 0;
    while (!try_read_lock()) {
      try_times++;

      /* busy-wait */
      if (try_times > 128) {
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
      } else if (try_times > 32) {
        std::this_thread::yield();
      }
    }
  }

  void read_unlock() { try_read_unlock(); }

  bool is_read_locked() { return lock_status_.load(std::memory_order_acquire) >= 2; }

  bool try_read_lock() {
    int32_t src_status = lock_status_.load(std::memory_order_acquire);
    while (true) {
      // failed if already lock writable
      if (src_status & WRITE_LOCK_FLAG) {
        return false;
      }

      // max locker
      if (src_status >= MAX_READ_LOCK_HOLDER) {
        return false;
      }

      int32_t dst_status = src_status + 2;
      if (lock_status_.compare_exchange_weak(src_status, dst_status, std::memory_order_acq_rel)) {
        return true;
      }
    }
  }

  bool try_read_unlock() {
    int32_t src_status = lock_status_.load(std::memory_order_acquire);
    while (true) {
      if (src_status < 2) {
        return false;
      }

      int32_t dst_status = src_status - 2;
      if (lock_status_.compare_exchange_weak(src_status, dst_status, std::memory_order_acq_rel)) {
        return true;
      }
    }
  }

  void write_lock() {
    bool is_already_lock_writable = false;
    unsigned char try_times = 0;

    while (true) {
      int32_t src_status = lock_status_.load(std::memory_order_acquire);
      // already lock writable
      if (is_already_lock_writable) {
        if (src_status < 2) {
          return;
        }

        try_times++;

        /* busy-wait */
        if (try_times > 128) {
          std::this_thread::sleep_for(std::chrono::milliseconds(1));
        } else if (try_times > 32) {
          std::this_thread::yield();
        }
        continue;
      }

      // failed if already locked
      if (src_status & WRITE_LOCK_FLAG) {
        try_times++;

        /* busy-wait */
        if (try_times > 128) {
          std::this_thread::sleep_for(std::chrono::milliseconds(1));
        } else if (try_times > 32) {
          std::this_thread::yield();
        }
        continue;
      }

      // lock writable and then wait for all read lock to free
      int32_t dst_status = src_status + WRITE_LOCK_FLAG;
      if (lock_status_.compare_exchange_weak(src_status, dst_status, std::memory_order_acq_rel)) {
        is_already_lock_writable = true;
      }
    }
  }

  void write_unlock() { try_write_unlock(); }

  bool is_write_locked() { return 0 != (lock_status_.load(std::memory_order_acquire) & WRITE_LOCK_FLAG); }

  bool try_write_lock() {
    int32_t src_status = lock_status_.load(std::memory_order_acquire);
    while (true) {
      // failed if already locked
      if (src_status & WRITE_LOCK_FLAG) {
        return false;
      }

      // failed if there is any read lock
      if (src_status >= 2) {
        return false;
      }

      int32_t dst_status = src_status + WRITE_LOCK_FLAG;
      if (lock_status_.compare_exchange_weak(src_status, dst_status, std::memory_order_acq_rel)) {
        return true;
      }
    }
  }

  bool try_write_unlock() {
    int32_t src_status = lock_status_.load(std::memory_order_acquire);
    while (true) {
      if (0 == (src_status & WRITE_LOCK_FLAG)) {
        return false;
      }

      int32_t dst_status = src_status - WRITE_LOCK_FLAG;
      if (lock_status_.compare_exchange_weak(src_status, dst_status, std::memory_order_acq_rel)) {
        return true;
      }
    }
  }
};
}  // namespace lock
}  // namespace excel
