#include "config_traits.h"
#include <gtest/gtest.h>

namespace excel {
namespace traits {

TEST(ConfigTraitsTest, MakeSharedTest) {
  struct TestStruct {
    int value;
    explicit TestStruct(int v) : value(v) {}
  };

  // Test normal case
  auto ptr = config_traits<type_guard>::make_shared<TestStruct>(42);
  ASSERT_NE(ptr, nullptr);
  EXPECT_EQ(ptr->value, 42);

  // Test edge case with zero arguments
  auto ptr2 = config_traits<type_guard>::make_shared<TestStruct>(0);
  ASSERT_NE(ptr2, nullptr);
  EXPECT_EQ(ptr2->value, 0);
}

TEST(ConfigTraitsTest, ConstPointerCastTest) {
  struct TestStruct {
    int value;
    explicit TestStruct(int v) : value(v) {}
  };

  // Test normal case
  auto ptr = config_traits<type_guard>::make_shared<TestStruct>(42);
  auto constPtr = std::const_pointer_cast<const TestStruct>(ptr);
  auto castedPtr = config_traits<type_guard>::const_pointer_cast<TestStruct>(constPtr);
  ASSERT_NE(castedPtr, nullptr);
  EXPECT_EQ(castedPtr->value, 42);

  // Test edge case with nullptr
  std::shared_ptr<const TestStruct> nullPtr;
  auto castedNullPtr = config_traits<type_guard>::const_pointer_cast<TestStruct>(nullPtr);
  EXPECT_EQ(castedNullPtr, nullptr);
}

} // namespace traits
} // namespace excel