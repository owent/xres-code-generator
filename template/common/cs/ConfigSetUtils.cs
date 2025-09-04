using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using static excel.ConfigSetUtils;
using static System.Net.Mime.MediaTypeNames;

namespace excel
{
    public static class ConfigSetUtils
    {

        static ConfigSetUtils()
        {
            Default<int>.Value = 0;
            Default<float>.Value = 0f;
            Default<string>.Value = string.Empty;
            Default<bool>.Value = false;
        }

        public static class Default<T>
        {
            public static T Value = default(T);
        }

        public static bool IsDefault<T>(T value) where T : IEquatable<T> => Default<T>.Value.Equals(value);

        public static bool IsAnyDefault<T1>(ValueTuple<T1> value) where T1 : IEquatable<T1> => IsDefault(value.Item1);
        public static bool IsAnyDefault<T1, T2>(ValueTuple<T1, T2> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> => IsDefault(value.Item1) || IsDefault(value.Item2);
        public static bool IsAnyDefault<T1, T2, T3>(ValueTuple<T1, T2, T3> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> => IsDefault(value.Item1) || IsDefault(value.Item2) || IsDefault(value.Item3);
        public static bool IsAnyDefault<T1, T2, T3, T4>(ValueTuple<T1, T2, T3, T4> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> => IsDefault(value.Item1) || IsDefault(value.Item2) || IsDefault(value.Item3) || IsDefault(value.Item4);
        public static bool IsAnyDefault<T1, T2, T3, T4, T5>(ValueTuple<T1, T2, T3, T4, T5> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> where T5 : IEquatable<T5> => IsDefault(value.Item1) || IsDefault(value.Item2) || IsDefault(value.Item3) || IsDefault(value.Item4) || IsDefault(value.Item5);
        public static bool IsAnyDefault<T1, T2, T3, T4, T5, T6>(ValueTuple<T1, T2, T3, T4, T5, T6> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> where T5 : IEquatable<T5> where T6 : IEquatable<T6> => IsDefault(value.Item1) || IsDefault(value.Item2) || IsDefault(value.Item3) || IsDefault(value.Item4) || IsDefault(value.Item5) || IsDefault(value.Item6);
        public static bool IsAnyDefault<T1, T2, T3, T4, T5, T6, T7>(ValueTuple<T1, T2, T3, T4, T5, T6, T7> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> where T5 : IEquatable<T5> where T6 : IEquatable<T6> where T7 : IEquatable<T7> => IsDefault(value.Item1) || IsDefault(value.Item2) || IsDefault(value.Item3) || IsDefault(value.Item4) || IsDefault(value.Item5) || IsDefault(value.Item6) || IsDefault(value.Item7);

        public static bool IsAllDefault<T1>(ValueTuple<T1> value) where T1 : IEquatable<T1> => IsDefault(value.Item1);
        public static bool IsAllDefault<T1, T2>(ValueTuple<T1, T2> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> => IsDefault(value.Item1) && IsDefault(value.Item2);
        public static bool IsAllDefault<T1, T2, T3>(ValueTuple<T1, T2, T3> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> => IsDefault(value.Item1) && IsDefault(value.Item2) && IsDefault(value.Item3);
        public static bool IsAllDefault<T1, T2, T3, T4>(ValueTuple<T1, T2, T3, T4> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> => IsDefault(value.Item1) && IsDefault(value.Item2) && IsDefault(value.Item3) && IsDefault(value.Item4);
        public static bool IsAllDefault<T1, T2, T3, T4, T5>(ValueTuple<T1, T2, T3, T4, T5> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> where T5 : IEquatable<T5> => IsDefault(value.Item1) && IsDefault(value.Item2) && IsDefault(value.Item3) && IsDefault(value.Item4) && IsDefault(value.Item5);
        public static bool IsAllDefault<T1, T2, T3, T4, T5, T6>(ValueTuple<T1, T2, T3, T4, T5, T6> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> where T5 : IEquatable<T5> where T6 : IEquatable<T6> => IsDefault(value.Item1) && IsDefault(value.Item2) && IsDefault(value.Item3) && IsDefault(value.Item4) && IsDefault(value.Item5) && IsDefault(value.Item6);
        public static bool IsAllDefault<T1, T2, T3, T4, T5, T6, T7>(ValueTuple<T1, T2, T3, T4, T5, T6, T7> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> where T5 : IEquatable<T5> where T6 : IEquatable<T6> where T7 : IEquatable<T7> => IsDefault(value.Item1) && IsDefault(value.Item2) && IsDefault(value.Item3) && IsDefault(value.Item4) && IsDefault(value.Item5) && IsDefault(value.Item6) && IsDefault(value.Item7);
    }
}
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using static excel.ConfigSetUtils;
using static System.Net.Mime.MediaTypeNames;

namespace excel
{
    public static class ConfigSetUtils
    {

        static ConfigSetUtils()
        {
            Default<int>.Value = 0;
            Default<float>.Value = 0f;
            Default<string>.Value = string.Empty;
            Default<bool>.Value = false;
        }

        public static class Default<T>
        {
            public static T Value = default(T);
        }

        public static bool IsDefault<T>(T value) where T : IEquatable<T> => Default<T>.Value.Equals(value);

        public static bool IsAnyDefault<T1>(ValueTuple<T1> value) where T1 : IEquatable<T1> => IsDefault(value.Item1);
        public static bool IsAnyDefault<T1, T2>(ValueTuple<T1, T2> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> => IsDefault(value.Item1) || IsDefault(value.Item2);
        public static bool IsAnyDefault<T1, T2, T3>(ValueTuple<T1, T2, T3> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> => IsDefault(value.Item1) || IsDefault(value.Item2) || IsDefault(value.Item3);
        public static bool IsAnyDefault<T1, T2, T3, T4>(ValueTuple<T1, T2, T3, T4> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> => IsDefault(value.Item1) || IsDefault(value.Item2) || IsDefault(value.Item3) || IsDefault(value.Item4);
        public static bool IsAnyDefault<T1, T2, T3, T4, T5>(ValueTuple<T1, T2, T3, T4, T5> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> where T5 : IEquatable<T5> => IsDefault(value.Item1) || IsDefault(value.Item2) || IsDefault(value.Item3) || IsDefault(value.Item4) || IsDefault(value.Item5);
        public static bool IsAnyDefault<T1, T2, T3, T4, T5, T6>(ValueTuple<T1, T2, T3, T4, T5, T6> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> where T5 : IEquatable<T5> where T6 : IEquatable<T6> => IsDefault(value.Item1) || IsDefault(value.Item2) || IsDefault(value.Item3) || IsDefault(value.Item4) || IsDefault(value.Item5) || IsDefault(value.Item6);
        public static bool IsAnyDefault<T1, T2, T3, T4, T5, T6, T7>(ValueTuple<T1, T2, T3, T4, T5, T6, T7> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> where T5 : IEquatable<T5> where T6 : IEquatable<T6> where T7 : IEquatable<T7> => IsDefault(value.Item1) || IsDefault(value.Item2) || IsDefault(value.Item3) || IsDefault(value.Item4) || IsDefault(value.Item5) || IsDefault(value.Item6) || IsDefault(value.Item7);

        public static bool IsAllDefault<T1>(ValueTuple<T1> value) where T1 : IEquatable<T1> => IsDefault(value.Item1);
        public static bool IsAllDefault<T1, T2>(ValueTuple<T1, T2> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> => IsDefault(value.Item1) && IsDefault(value.Item2);
        public static bool IsAllDefault<T1, T2, T3>(ValueTuple<T1, T2, T3> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> => IsDefault(value.Item1) && IsDefault(value.Item2) && IsDefault(value.Item3);
        public static bool IsAllDefault<T1, T2, T3, T4>(ValueTuple<T1, T2, T3, T4> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> => IsDefault(value.Item1) && IsDefault(value.Item2) && IsDefault(value.Item3) && IsDefault(value.Item4);
        public static bool IsAllDefault<T1, T2, T3, T4, T5>(ValueTuple<T1, T2, T3, T4, T5> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> where T5 : IEquatable<T5> => IsDefault(value.Item1) && IsDefault(value.Item2) && IsDefault(value.Item3) && IsDefault(value.Item4) && IsDefault(value.Item5);
        public static bool IsAllDefault<T1, T2, T3, T4, T5, T6>(ValueTuple<T1, T2, T3, T4, T5, T6> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> where T5 : IEquatable<T5> where T6 : IEquatable<T6> => IsDefault(value.Item1) && IsDefault(value.Item2) && IsDefault(value.Item3) && IsDefault(value.Item4) && IsDefault(value.Item5) && IsDefault(value.Item6);
        public static bool IsAllDefault<T1, T2, T3, T4, T5, T6, T7>(ValueTuple<T1, T2, T3, T4, T5, T6, T7> value) where T1 : IEquatable<T1> where T2 : IEquatable<T2> where T3 : IEquatable<T3> where T4 : IEquatable<T4> where T5 : IEquatable<T5> where T6 : IEquatable<T6> where T7 : IEquatable<T7> => IsDefault(value.Item1) && IsDefault(value.Item2) && IsDefault(value.Item3) && IsDefault(value.Item4) && IsDefault(value.Item5) && IsDefault(value.Item6) && IsDefault(value.Item7);
    }
}
