#ifndef CONFIG_EXCEL_CONFIG_SPIN_RWLOCK_H
#define CONFIG_EXCEL_CONFIG_SPIN_RWLOCK_H

#pragma once

#include <atomic>
#include <thread>
#include <chrono>

#ifndef CONFIG_EXCEL_CONFIG_API_HEAD_ONLY
#if defined(__GNUC__) && !defined(__ibmxl__)
//  GNU C++/Clang
//
// Dynamic shared object (DSO) and dynamic-link library (DLL) support
//
#if (__GNUC__ >= 4) && !(defined(_WIN32) || defined(__WIN32__) || defined(WIN32) || defined(__CYGWIN__))
#define CONFIG_EXCEL_CONFIG_API_HEAD_ONLY __attribute__((__visibility__("default")))
#endif
#endif

#ifndef CONFIG_EXCEL_CONFIG_API_HEAD_ONLY
#define CONFIG_EXCEL_CONFIG_API_HEAD_ONLY
#endif

#endif

namespace excel {
    namespace lock {
        namespace detail {
            template <typename TLock>
            struct CONFIG_EXCEL_CONFIG_API_HEAD_ONLY default_lock_action {
                bool operator()(TLock &lock) const {
                    lock.lock();
                    return true;
                }
            };

            template <typename TLock>
            struct CONFIG_EXCEL_CONFIG_API_HEAD_ONLY default_try_lock_action {
                bool operator()(TLock &lock) const { return lock.try_lock(); }
            };

            template <typename TLock>
            struct CONFIG_EXCEL_CONFIG_API_HEAD_ONLY default_unlock_action {
                void operator()(TLock &lock) const { lock.unlock(); }
            };

            template <typename TLock>
            struct CONFIG_EXCEL_CONFIG_API_HEAD_ONLY default_try_unlock_action {
                bool operator()(TLock &lock) const { return lock.try_unlock(); }
            };

            template <typename TLock>
            struct CONFIG_EXCEL_CONFIG_API_HEAD_ONLY default_read_lock_action {
                bool operator()(TLock &lock) const {
                    lock.read_lock();
                    return true;
                }
            };

            template <typename TLock>
            struct CONFIG_EXCEL_CONFIG_API_HEAD_ONLY default_read_unlock_action {
                void operator()(TLock &lock) const { lock.read_unlock(); }
            };

            template <typename TLock>
            struct CONFIG_EXCEL_CONFIG_API_HEAD_ONLY default_write_lock_action {
                bool operator()(TLock &lock) const {
                    lock.write_lock();
                    return true;
                }
            };

            template <typename TLock>
            struct CONFIG_EXCEL_CONFIG_API_HEAD_ONLY default_write_unlock_action {
                void operator()(TLock &lock) const { lock.write_unlock(); }
            };
        } // namespace detail

        template <typename TLock, typename TLockAct = detail::default_lock_action<TLock>,
                  typename TUnlockAct = detail::default_unlock_action<TLock> >
        class CONFIG_EXCEL_CONFIG_API_HEAD_ONLY lock_holder {
        public:
            typedef TLock value_type;

            lock_holder(TLock &lock) : lock_flag_(&lock) {
                if (false == TLockAct()(lock)) {
                    lock_flag_ = NULL;
                }
            }

            ~lock_holder() {
                if (NULL != lock_flag_) {
                    TUnlockAct()(*lock_flag_);
                }
            }

            bool is_available() const { return NULL != lock_flag_; }

        private:
            lock_holder(const lock_holder &) = delete;
            lock_holder &operator=(const lock_holder &) = delete;

        private:
            value_type *lock_flag_;
        };

        template <typename TLock>
        class CONFIG_EXCEL_CONFIG_API_HEAD_ONLY read_lock_holder
            : public lock_holder<TLock, detail::default_read_lock_action<TLock>, detail::default_read_unlock_action<TLock> > {
        public:
            read_lock_holder(TLock &lock)
                : lock_holder<TLock, detail::default_read_lock_action<TLock>, detail::default_read_unlock_action<TLock> >(lock) {}
        };

        template <typename TLock>
        class CONFIG_EXCEL_CONFIG_API_HEAD_ONLY write_lock_holder
            : public lock_holder<TLock, detail::default_write_lock_action<TLock>, detail::default_write_unlock_action<TLock> > {
        public:
            write_lock_holder(TLock &lock)
                : lock_holder<TLock, detail::default_write_lock_action<TLock>, detail::default_write_unlock_action<TLock> >(lock) {}
        };

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
                bool          is_already_lock_writable = false;
                unsigned char try_times                = 0;

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
    } // namespace lock
} // namespace excel

#endif
