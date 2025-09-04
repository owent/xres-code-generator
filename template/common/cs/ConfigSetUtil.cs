using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static excel.ConfigSetUtil;

namespace excel
{
    public static class ConfigSetUtil
    {

        static ConfigSetUtil()
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
    }
}
