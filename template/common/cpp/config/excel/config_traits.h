// Copyright 2024 xresloader

#pragma once

#include <map>
#include <memory>
#include <string>
#include <tuple>
#include <type_traits>
#include <unordered_map>
#include <utility>

#ifndef EXCEL_CONFIG_SYMBOL_VISIBLE
#  if defined(__GNUC__) && __GNUC__ >= 4
#    if !(defined(_WIN32) || defined(__WIN32__) || defined(WIN32) || defined(__CYGWIN__))
#      define EXCEL_CONFIG_SYMBOL_VISIBLE __attribute__((__visibility__("default")))
#    endif
#  endif
#endif

#ifndef EXCEL_CONFIG_SYMBOL_VISIBLE
#  define EXCEL_CONFIG_SYMBOL_VISIBLE
#endif

namespace excel {
namespace traits {

// 使用偏特化来注入内部数据结构和Hash算法变更
/**
template <>
struct EXCEL_CONFIG_SYMBOL_VISIBLE hash_traits<hash_guard> {
  template <class Y>
  using hash = std::hash<Y>;
};

template <>
struct EXCEL_CONFIG_SYMBOL_VISIBLE config_traits<type_guard> : public type_guard {
  template <class Key, class Value>
  using map_type = std::map<Key, Value>;

  template <class Y>
  using shared_ptr = util::memory::strong_rc_ptr<Y>;

  template <class Y, class... Args>
  inline static util::memory::strong_rc_ptr<Y> make_shared(Args&&... args) {
    return util::memory::make_strong_rc<Y>(std::forward<Args>(args)...);
  }

  template <class Y, class... Args>
  inline static util::memory::strong_rc_ptr<Y> const_pointer_cast(Args&&... args) {
    return util::memory::const_pointer_cast<Y>(std::forward<Args>(args)...);
  }
};
**/

template <class Y>
struct EXCEL_CONFIG_SYMBOL_VISIBLE tuple_hasher;

struct EXCEL_CONFIG_SYMBOL_VISIBLE hash_guard {};

template <class T>
struct EXCEL_CONFIG_SYMBOL_VISIBLE hash_traits {
  template <class Y>
  using hash = tuple_hasher<Y>;
};

struct EXCEL_CONFIG_SYMBOL_VISIBLE type_guard {
  template <class Key, class Value>
  using map_type = std::unordered_map<Key, Value, hash_traits<hash_guard>::template hash<Key>>;

  template <class Y>
  using shared_ptr = std::shared_ptr<Y>;

  template <class Y, class... Args>
  inline static std::shared_ptr<Y> make_shared(Args&&... args) {
    return std::make_shared<Y>(std::forward<Args>(args)...);
  }

  template <class Y, class... Args>
  inline static std::shared_ptr<Y> const_pointer_cast(Args&&... args) {
    return std::const_pointer_cast<Y>(std::forward<Args>(args)...);
  }
};

template <class T>
struct EXCEL_CONFIG_SYMBOL_VISIBLE config_traits;

template <std::size_t Index, std::size_t Size>
struct EXCEL_CONFIG_SYMBOL_VISIBLE tuple_hasher_enable
    : public std::conditional<(Index < Size), std::true_type, std::false_type>::type {};

template <std::size_t Index, bool Enable>
struct EXCEL_CONFIG_SYMBOL_VISIBLE tuple_hasher_at_index;

template <std::size_t Index>
struct EXCEL_CONFIG_SYMBOL_VISIBLE tuple_hasher_at_index<Index, false> {
  template <class... Args>
  std::size_t operator()(std::size_t seed, const std::tuple<Args...>&) const noexcept {
    return seed;
  }
};

template <std::size_t Index>
struct EXCEL_CONFIG_SYMBOL_VISIBLE tuple_hasher_at_index<Index, true> {
  template <class... Args>
  std::size_t operator()(std::size_t seed, const std::tuple<Args...>& t) const {
    using hash_type =
        hash_traits<hash_guard>::template hash<typename std::tuple_element<Index, std::tuple<Args...>>::type>;

    seed ^= hash_type()(std::get<Index>(t)) + 0x9e3779b9 + (seed << 6) + (seed >> 2);
    return tuple_hasher_at_index<Index + 1, tuple_hasher_enable<Index + 1, sizeof...(Args)>::value>()(seed, t);
  }
};

template <class T>
struct EXCEL_CONFIG_SYMBOL_VISIBLE tuple_hasher {
  template <class... Args>
  std::size_t operator()(const std::tuple<Args...>& t) const {
    return tuple_hasher_at_index<0, tuple_hasher_enable<0, sizeof...(Args)>::value>()(0, t);
  }

  template <class... Args>
  std::size_t operator()(std::tuple<Args...>&& t) const {
    return tuple_hasher_at_index<0, tuple_hasher_enable<0, sizeof...(Args)>::value>()(0, t);
  }

  template <class Arg>
  std::size_t operator()(Arg&& t) const {
    return std::hash<typename std::remove_cv<typename std::remove_reference<Arg>::type>::type>()(std::forward<Arg>(t));
  }
};

template <class T>
struct EXCEL_CONFIG_SYMBOL_VISIBLE config_traits {
  template <class Key, class Value>
  using map_type = type_guard::map_type<Key, Value>;

  template <class Y>
  using shared_ptr = type_guard::shared_ptr<Y>;

  template <class Y, class... Args>
  inline static shared_ptr<Y> make_shared(Args&&... args) {
    return type_guard::make_shared<Y>(std::forward<Args>(args)...);
  }

  template <class Y, class... Args>
  inline static std::shared_ptr<Y> const_pointer_cast(Args&&... args) {
    return type_guard::const_pointer_cast<Y>(std::forward<Args>(args)...);
  }
};

EXCEL_CONFIG_SYMBOL_VISIBLE inline bool value_traits_is_default(const std::string& input) noexcept {
  return input.empty();
}

EXCEL_CONFIG_SYMBOL_VISIBLE inline bool value_traits_is_default(bool input) noexcept { return !input; }

template <class T>
EXCEL_CONFIG_SYMBOL_VISIBLE inline bool value_traits_is_default(const T& input) noexcept {
  return static_cast<T>(0) == static_cast<T>(input);
}

template <std::size_t Index, std::size_t Size>
struct EXCEL_CONFIG_SYMBOL_VISIBLE key_tuple_trait_enable
    : public std::conditional<(Index < Size), std::true_type, std::false_type>::type {};

template <std::size_t Index, bool Enable>
struct EXCEL_CONFIG_SYMBOL_VISIBLE key_tuple_trait_any_default_at_index;

template <std::size_t Index>
struct EXCEL_CONFIG_SYMBOL_VISIBLE key_tuple_trait_any_default_at_index<Index, false> {
  template <class... Args>
  bool operator()(const std::tuple<Args...>&) const noexcept {
    return false;
  }
};

template <std::size_t Index>
struct EXCEL_CONFIG_SYMBOL_VISIBLE key_tuple_trait_any_default_at_index<Index, true> {
  template <class... Args>
  bool operator()(const std::tuple<Args...>& t) const noexcept {
    if (value_traits_is_default(std::get<Index>(t))) {
      return true;
    }

    return key_tuple_trait_any_default_at_index<Index + 1, key_tuple_trait_enable<Index + 1, sizeof...(Args)>::value>()(
        t);
  }
};

template <std::size_t Index, bool Enable>
struct EXCEL_CONFIG_SYMBOL_VISIBLE key_tuple_trait_all_default_at_index;

template <std::size_t Index>
struct EXCEL_CONFIG_SYMBOL_VISIBLE key_tuple_trait_all_default_at_index<Index, false> {
  template <class... Args>
  bool operator()(const std::tuple<Args...>&) const noexcept {
    return true;
  }
};

template <std::size_t Index>
struct EXCEL_CONFIG_SYMBOL_VISIBLE key_tuple_trait_all_default_at_index<Index, true> {
  template <class... Args>
  bool operator()(const std::tuple<Args...>& t) const noexcept {
    if (!value_traits_is_default(std::get<Index>(t))) {
      return false;
    }

    return key_tuple_trait_all_default_at_index<Index + 1, key_tuple_trait_enable<Index + 1, sizeof...(Args)>::value>()(
        t);
  }
};

template <class... Args>
struct EXCEL_CONFIG_SYMBOL_VISIBLE key_traits {
  inline static bool check_any_default(const std::tuple<Args...>& t) noexcept {
    return key_tuple_trait_any_default_at_index<0, key_tuple_trait_enable<0, sizeof...(Args)>::value>()(t);
  }

  inline static bool check_all_default(const std::tuple<Args...>& t) noexcept {
    return key_tuple_trait_all_default_at_index<0, key_tuple_trait_enable<0, sizeof...(Args)>::value>()(t);
  }
};

}  // namespace traits
}  // namespace excel
