#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import stat
import sys
import codecs
import shutil
import sysconfig
import re
import threading
import concurrent.futures
from subprocess import PIPE, Popen, TimeoutExpired

script_dir = os.path.dirname(os.path.realpath(__file__))
LOCAL_WOKER_POOL: concurrent.futures.ThreadPoolExecutor = None
LOCAL_WOKER_FUTURES = dict()


class MakoModuleTempDir:
    def __init__(self, prefix_path):
        import tempfile

        if not os.path.exists(prefix_path):
            os.makedirs(prefix_path)
        self.directory_path = tempfile.mkdtemp(suffix="", prefix="", dir=prefix_path)

    def __del__(self):
        if (
            self.directory_path is not None
            and os.path.exists(self.directory_path)
            and os.path.isdir(self.directory_path)
        ):
            shutil.rmtree(self.directory_path, ignore_errors=True)
            self.directory_path = None


if sys.platform == "win32":

    def test_windows_abs_path(paths):
        if len(paths) != 2:
            return False
        if len(paths[0]) != 1:
            return False
        return paths[1][0:1] == "/" or paths[1][0:1] == "\\"


def print_exception_with_traceback(e: Exception, fmt: str = None, *args):
    import traceback

    if fmt:
        if not fmt.startswith("[ERROR]:"):
            fmt = "[ERROR]: " + fmt
        if not fmt.endswith("\n") and not fmt.endswith("\r"):
            fmt = fmt + "\n"
        sys.stderr.write(fmt.format(*args))

    sys.stderr.write("[ERROR]: {0}.\n{1}\n".format(str(e), traceback.format_exc()))


def __format_codes(output_file, data, clang_format_path, clang_format_rule_re):
    if not clang_format_path or not clang_format_rule_re:
        return data
    if clang_format_rule_re.search(output_file) is None:
        return data
    try:
        pexec = Popen(
            [clang_format_path, "--assume-filename={}".format(output_file)],
            stdin=PIPE,
            stdout=PIPE,
            stderr=None,
            shell=False,
        )
        (stdout, _stderr) = pexec.communicate(data)
        if pexec.returncode == 0:
            return stdout
        return data

    except Exception as e:
        print_exception_with_traceback(e, "format code file {0} failed.", output_file)
        return data


def __worker_action_write_code_if_different(
    output_file, encoding, content, clang_format_path, clang_format_rule_re
):
    data = __format_codes(
        output_file,
        content.encode(encoding),
        clang_format_path,
        clang_format_rule_re,
    )

    content_changed = False
    if not os.path.exists(output_file):
        content_changed = True
    else:
        old_data = open(output_file, mode="rb").read()
        if old_data != data:
            content_changed = True

    if content_changed:
        open(output_file, mode="wb").write(data)


def write_code_if_different(
    output_file, encoding, content, clang_format_path, clang_format_rule_re
):
    global LOCAL_WOKER_POOL
    global LOCAL_WOKER_FUTURES
    if LOCAL_WOKER_POOL is None:
        LOCAL_WOKER_POOL = concurrent.futures.ThreadPoolExecutor()

    future = LOCAL_WOKER_POOL.submit(
        __worker_action_write_code_if_different,
        output_file,
        encoding,
        content,
        clang_format_path,
        clang_format_rule_re,
    )
    LOCAL_WOKER_FUTURES[future] = {"output_file": output_file}


def decode_rule(pattern):
    mode = None
    input = None
    output = None
    rules = pattern.split(":")
    if len(rules) == 1:
        input = rules[0]
        return mode, input, output
    # D: Drive Name
    # F: File Path Without Drive
    # M: Mode
    if len(rules[0]) == 0:
        if sys.platform == "win32":
            if len(rules) > 2 and test_windows_abs_path(rules[1:3]):
                # :D:\\F
                input = ":".join(rules[1:3])
                if len(rules) > 3:
                    # :D:\\F:D:\\F
                    output = ":".join(rules[3:])
            else:
                # :F
                input = rules[1]
                if len(rules) > 2:
                    # :F:D:\\F
                    output = ":".join(rules[2:])
        else:
            input = rules[1]
            if len(rules) > 2:
                output = rules[2]
        return mode, input, output
    elif len(rules[0]) > 1:
        input = rules[0]
        output = ":".join(rules[1:])
        return mode, input, output
    if sys.platform == "win32":
        if test_windows_abs_path(rules[0:2]):
            # D:\\F
            input = ":".join(rules[0:2])
            if len(rules) > 2:
                # D:\\F:[D:\\]F
                output = ":".join(rules[2:])
        elif (
            len(rules) > 2
            and test_windows_abs_path(rules[1:3])
            and os.path.exists(rules[0])
        ):
            # F:D:\\F
            input = rules[0]
            output = ":".join(rules[1:3])
        else:
            mode = rules[0].lower()
            if len(rules) == 2:
                # M:F
                input = rules[1]
            elif test_windows_abs_path(rules[1:3]):
                # M:D:\\F
                input = ":".join(rules[1:3])
                if len(rules) > 3:
                    # M:D:\\F:[D:\\]F
                    output = ":".join(rules[3:])
            else:
                # M:F
                input = rules[1]
                if len(rules) > 2:
                    # M:F:[D:\\]F
                    output = ":".join(rules[2:])
    else:
        if len(rules) > 2:
            mode = rules[0].lower()
            input = rules[1]
            output = rules[2]
        else:
            if os.path.exists(rules[0]):
                input = rules[0]
                output = rules[1]
            else:
                mode = rules[0].lower()
                input = rules[1]
    return mode, input, output


def add_package_prefix_paths(packag_paths):
    """See https://docs.python.org/3/install/#how-installation-works"""
    append_paths = []
    for path in packag_paths:
        for add_package_bin_path in [
            os.path.join(path, "bin"),
            os.path.join(path, "local", "bin"),
        ]:
            if os.path.exists(add_package_bin_path):
                if sys.platform.lower() == "win32":
                    os.environ["PATH"] = add_package_bin_path + ";" + os.environ["PATH"]
                else:
                    os.environ["PATH"] = add_package_bin_path + ":" + os.environ["PATH"]

        python_version_path = "python{0}".format(sysconfig.get_python_version())
        for add_package_lib_path in [
            os.path.join(path, "lib", python_version_path, "site-packages"),
            os.path.join(path, "local", "lib", python_version_path, "site-packages"),
            os.path.join(path, "lib64", python_version_path, "site-packages"),
            os.path.join(path, "local", "lib64", python_version_path, "site-packages"),
        ]:
            if os.path.exists(add_package_lib_path):
                append_paths.append(add_package_lib_path)

        add_package_lib_path_for_win = os.path.join(path, "Lib", "site-packages")
        if os.path.exists(add_package_lib_path_for_win):
            append_paths.append(add_package_lib_path_for_win)
    append_paths.extend(sys.path)
    sys.path = append_paths


def main():
    # lizard forgives
    global LOCAL_WOKER_POOL
    global LOCAL_WOKER_FUTURES

    os.environ["PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION"] = "python"
    from optparse import OptionParser

    usage = "%(prog)s -p <pb file> -o <output dir> [-i <additional template dirs>...] [-g <global templates>...] [-m <message templates>...] [other options...] [custom rules or field rules]"
    parser = OptionParser(usage)
    parser.add_option(
        "-v",
        "--version",
        action="store_true",
        help="show version and exit",
        dest="version",
        default=False,
    )
    parser.add_option(
        "--global-package",
        action="store",
        help="set global package name(namespace, passed as global_package into template)",
        dest="global_package",
        default="excel",
    )
    parser.add_option(
        "--msg-prefix",
        action="store",
        help="set class name prefix for each message generated",
        dest="msg_prefix",
        default="config_set_",
    )
    parser.add_option(
        "-g",
        "--global",
        action="append",
        help="add global template",
        dest="global_template",
        default=[],
    )
    parser.add_option(
        "-m",
        "--message",
        action="append",
        help="add message template(H:<file name> for header and S:<file name> for source)",
        dest="message_template",
        default=[],
    )
    parser.add_option(
        "-l",
        "--loader",
        action="append",
        help="add loader template(H:<file name> for header and S:<file name> for source)",
        dest="loader_template",
        default=[],
    )
    parser.add_option(
        "-f",
        "--file",
        action="append",
        help="add file template(H:<file name> for header and S:<file name> for source)",
        dest="file_template",
        default=[],
    )
    parser.add_option(
        "--file-ignore-package",
        action="append",
        help="ignore file in of packages",
        dest="file_ignore_package",
        default=[],
    )
    parser.add_option(
        "--file-include",
        action="append",
        help="select only file name match the include rule(by regex)",
        dest="file_include_rule",
        default=[],
    )
    parser.add_option(
        "--file-exclude",
        action="append",
        help="skip file name match the exclude rule(by regex)",
        dest="file_exclude_rule",
        default=[],
    )
    parser.add_option(
        "--file-include-well-known-types",
        action="store_true",
        help="generate file templates for well known types",
        dest="file_include_well_known_types",
        default=False,
    )
    parser.add_option(
        "--file-include-well-known-type",
        action="append",
        help="generate file templates only for included well known types",
        dest="file_include_well_known_type",
        default=[],
    )
    parser.add_option(
        "--file-exclude-well-known-type",
        action="append",
        help="generate file templates for well known types but exclude some of them",
        dest="file_exclude_well_known_type",
        default=[],
    )
    parser.add_option(
        "--set",
        action="append",
        help="set custom variables for rendering templates.",
        dest="set_vars",
        default=[],
    )
    parser.add_option(
        "-p", "--pb", action="append", help="set pb file path", dest="pb", default=[]
    )
    parser.add_option(
        "--pb-exclude-file",
        action="append",
        help="ignore pb file pattern(regex)",
        dest="pb_exclude_file",
        default=[],
    )
    parser.add_option(
        "--pb-exclude-package",
        action="append",
        help="ignore pb package pattern(regex)",
        dest="pb_exclude_package",
        default=[],
    )
    parser.add_option(
        "-o",
        "--output-dir",
        action="store",
        help="set output directory",
        dest="output_dir",
        default=None,
    )
    parser.add_option(
        "-i",
        "--input-dir",
        action="append",
        help="add tempalte directory",
        dest="input_dir",
        default=[],
    )
    parser.add_option(
        "--proto-v3",
        action="store_true",
        help="set proto v3 mode",
        dest="proto_v3",
        default=False,
    )
    parser.add_option(
        "-t",
        "--tag",
        action="append",
        help="just generate message for tags",
        dest="tags",
        default=[],
    )
    parser.add_option(
        "-e",
        "--exclude-tags",
        action="append",
        help="do not generate message for tags",
        dest="exclude_tags",
        default=[],
    )
    parser.add_option(
        "-c",
        "--custom-group",
        action="append",
        help="add custom group with format 'NAME:FILE_NAME'(example: custom_config_group:custom_group_fields.h.mako)",
        dest="custom_group",
        default=[],
    )
    parser.add_option(
        "--pb-include-prefix",
        action="store",
        help="set include prefix of generated protobuf header",
        dest="pb_include_prefix",
        default="",
    )
    parser.add_option(
        "--print-output-file",
        action="store_true",
        help="print output file list but generate it",
        dest="print_output_file",
        default=False,
    )
    parser.add_option(
        "--no-overwrite",
        action="store_true",
        help="do not overwrite output file if it's already exists.",
        dest="no_overwrite",
        default=False,
    )
    parser.add_option(
        "--quiet",
        action="store_true",
        help="do not show the detail of generated files.",
        dest="quiet",
        default=False,
    )
    parser.add_option(
        "--encoding",
        action="store",
        help="set encoding of output file(default: utf-8-sig).",
        dest="encoding",
        default="utf-8-sig",
    )
    parser.add_option(
        "--shared-outer-type",
        action="store",
        help="set common outer type(default: org.xresloader.pb.xresloader_datablocks).",
        dest="shared_outer_type",
        default="org.xresloader.pb.xresloader_datablocks",
    )
    parser.add_option(
        "--shared-outer-field",
        action="store",
        help="set common outer type(default: data_block).",
        dest="shared_outer_field",
        default="data_block",
    )
    parser.add_option(
        "--add-path",
        action="append",
        help="add path to python module(where to find protobuf,six,mako,print_style and etc...)",
        dest="add_path",
        default=[],
    )
    parser.add_option(
        "--add-package-prefix",
        action="append",
        help="add path to python module install prefix(where to find protobuf,six,mako,print_style and etc...)",
        dest="add_package_prefix",
        default=[],
    )
    parser.add_option(
        "--clang-format-path",
        action="store",
        help="set path of clang-format to format output codes",
        dest="clang_format_path",
        default=None,
    )
    parser.add_option(
        "--clang-format-rule",
        action="store",
        help="set regex rule for file path to use clang-format to format",
        dest="clang_format_rule",
        default="\\.(c|cc|cpp|cxx|h|hpp|hxx|i|ii|ixx|tcc|cppm|c\\+\\+|proto)$",
    )

    (options, left_args) = parser.parse_args()

    if options.version:
        print("1.1.0")
        sys.exit(0)

    def print_help_msg(err_code):
        parser.print_help()
        sys.exit(err_code)

    if options.output_dir is None or options.pb is None:
        print_help_msg(1)

    prepend_paths = []
    if options.add_path:
        prepend_paths.extend([x for x in options.add_path])
    sys.path.append(os.path.join(script_dir, "xrescode-utils"))
    sys.path.append(os.path.join(script_dir, "pb_extension"))
    prepend_paths.extend(sys.path)
    sys.path = prepend_paths
    add_package_prefix_paths(options.add_package_prefix)

    template_paths = options.input_dir
    template_paths.append(os.path.join(script_dir, "pb_extension"))
    template_paths.append(os.path.join(script_dir, "xrescode-utils"))
    template_paths.append(os.path.join(script_dir, "template"))

    pb_exclude_files = [re.compile(rule) for rule in options.pb_exclude_file]
    pb_exclude_packages = [re.compile(rule) for rule in options.pb_exclude_package]

    # parse pb file
    import pb_loader

    pb_set = pb_loader.PbDescSet(
        options.pb,
        tags=options.tags,
        msg_prefix=options.msg_prefix,
        proto_v3=options.proto_v3,
        pb_include_prefix=options.pb_include_prefix,
        exclude_tags=options.exclude_tags,
        shared_outer_type=options.shared_outer_type,
        shared_outer_field=options.shared_outer_field,
        index_extended_well_known_type=options.file_include_well_known_types,
        index_include_well_known_type=set(options.file_include_well_known_type),
        index_exclude_well_known_type=set(options.file_exclude_well_known_type),
        pb_exclude_files=pb_exclude_files,
        pb_exclude_packages=pb_exclude_packages,
    )

    for custom_var in options.set_vars:
        key_value_pair = custom_var.split("=")
        if len(key_value_pair) > 1:
            pb_set.set_custom_variable(
                key_value_pair[0].strip(), key_value_pair[1].strip()
            )
        elif key_value_pair:
            pb_set.set_custom_variable(key_value_pair[0].strip(), "")

    for cg in options.custom_group:
        name_idx = cg.find(":")
        if name_idx > 0 and name_idx < len(cg):
            pb_set.add_custom_blocks(cg[0:name_idx], cg[name_idx + 1 :])
    # render templates
    from mako.template import Template
    from mako.lookup import TemplateLookup
    from mako.runtime import supports_caller

    temp_dir_holder = MakoModuleTempDir(
        os.path.join(
            script_dir,
            ".mako_modules-{0}.{1}.{2}".format(
                sys.version_info[0], sys.version_info[1], sys.version_info[2]
            ),
        )
    )
    make_module_cache_dir = temp_dir_holder.directory_path

    clang_format_rule_re = re.compile(options.clang_format_rule, re.IGNORECASE)

    def gen_source(list_container, pb_file=None, pb_msg=None, loader=None):
        nonlocal clang_format_rule_re
        for rule in list_container:
            is_message_header = False
            is_message_source = False
            rule_mode, rule_input, rule_output = decode_rule(rule)
            if loader is not None:
                if rule_mode == "h":
                    is_message_header = True
                elif rule_mode == "s":
                    is_message_source = True

            source_template = rule_input
            output_name = None

            source_template_dir = os.path.realpath(os.path.dirname(source_template))
            lookup_dirs = [source_template_dir]
            lookup_dirs.extend(template_paths)
            project_lookup = TemplateLookup(
                directories=lookup_dirs, module_directory=make_module_cache_dir
            )
            source_tmpl = project_lookup.get_template(os.path.basename(source_template))
            suffix_pos = source_template.rfind(".")

            output_dir = os.getcwd()
            if options.output_dir is not None:
                output_dir = options.output_dir

            if rule_output is not None:
                output_render_tmpl = Template(rule_output, lookup=project_lookup)
                output_name = output_render_tmpl.render(
                    pb_set=pb_set,
                    pb_file=pb_file,
                    pb_msg=pb_msg,
                    loader=loader,
                    output_dir=output_dir,
                    output_file=rule_output,
                    input_file=source_template,
                    msg_prefix=options.msg_prefix,
                    global_package=options.global_package,
                )

            elif is_message_header and loader is not None:
                output_name = loader.get_cpp_header_path()
            elif is_message_source and loader is not None:
                output_name = loader.get_cpp_source_path()
            else:
                if suffix_pos < 0:
                    output_name = os.path.basename(source_template)
                else:
                    if source_template[suffix_pos + 1 :].lower() == "mako":
                        output_name = os.path.basename(source_template[0:suffix_pos])
                    else:
                        output_name = os.path.basename(source_template)
                if loader is not None and loader.code:
                    suffix_pos = output_name.rfind(".")
                    if suffix_pos < 0:
                        output_name = (
                            "{0}_{1}_{2}".format(
                                output_name,
                                loader.code.package.replace(".", "::"),
                                loader.code.class_name,
                            )
                            .replace("::", "_")
                            .replace("__", "_")
                        )
                    else:
                        output_name = (
                            "{0}_{1}_{2}{3}".format(
                                output_name[0:suffix_pos],
                                loader.code.package.replace(".", "::"),
                                loader.code.class_name,
                                output_name[suffix_pos:],
                            )
                            .replace("::", "_")
                            .replace("__", "_")
                        )

            output_name = os.path.join(options.output_dir, output_name)

            if options.print_output_file:
                print(output_name)
            else:
                if options.no_overwrite and os.path.exists(output_name):
                    if not options.quiet:
                        print(
                            "[XRESCODE] Ignore genarate template from {0} to {1}, already exists.".format(
                                source_template, output_name
                            )
                        )
                else:
                    if os.path.exists(output_name):
                        os.chmod(
                            output_name, stat.S_IRWXU + stat.S_IRWXG + stat.S_IRWXO
                        )
                    else:
                        output_dir = os.path.dirname(output_name)
                        if not os.path.exists(output_dir):
                            os.makedirs(output_dir)
                        else:
                            os.chmod(
                                output_dir,
                                stat.S_IRWXU + stat.S_IRWXG + stat.S_IRWXO,
                            )
                    if not options.quiet:
                        print(
                            "[XRESCODE] Genarate template from {0} to {1}".format(
                                source_template, output_name
                            )
                        )
                    render_output = source_tmpl.render(
                        pb_set=pb_set,
                        pb_msg=pb_msg,
                        pb_file=pb_file,
                        loader=loader,
                        output_dir=output_dir,
                        output_file=output_name,
                        input_file=source_template,
                        msg_prefix=options.msg_prefix,
                        global_package=options.global_package,
                    )
                    write_code_if_different(
                        str(output_name),
                        options.encoding,
                        str(render_output),
                        options.clang_format_path,
                        clang_format_rule_re,
                    )

    file_ignore_packages = set(options.file_ignore_package)
    file_include_rules = None
    file_exclude_rules = None
    if options.file_include_rule:
        for rule in options.file_include_rule:
            if file_include_rules is None:
                file_include_rules = []
            file_include_rules.append(re.compile(rule))
    if options.file_exclude_rule:
        for rule in options.file_exclude_rule:
            if file_exclude_rules is None:
                file_exclude_rules = []
            file_exclude_rules.append(re.compile(rule))

    gen_source(options.global_template, None, None, None)
    for pb_msg in pb_set.generate_message:
        gen_source(
            options.message_template, pb_file=pb_msg.pb_file, pb_msg=pb_msg, loader=None
        )
        for loader in pb_msg.loaders:
            gen_source(
                options.loader_template,
                pb_file=pb_msg.pb_file,
                pb_msg=pb_msg,
                loader=loader,
            )
    if options.file_template:
        for file_path in pb_set.pb_files:
            if file_ignore_packages and file_path in file_ignore_packages:
                continue
            if file_include_rules:
                selected = False
                for rule in file_include_rules:
                    if rule.match(file_path):
                        selected = True
                        break
                if not selected:
                    continue
            if file_exclude_rules:
                selected = True
                for rule in file_exclude_rules:
                    if rule.match(file_path):
                        selected = False
                        break
                if not selected:
                    continue
            gen_source(
                options.file_template,
                pb_file=pb_set.pb_files[file_path],
                pb_msg=None,
                loader=None,
            )

    for rule in left_args:
        if len(rule) < 2:
            sys.stderr.write("[XRESCODE ERROR] Invalid custom rule {0}\n".format(rule))
            continue
        rule_mode, rule_input, rule_output = decode_rule(rule)
        if rule_output is None:
            left_rule_desc = rule_input
        else:
            left_rule_desc = "{0}:{1}".format(rule_input, rule_output)
        if rule_mode == "g":
            gen_source([left_rule_desc], None, None, None)
        if rule_mode == "m":
            for pb_msg in pb_set.generate_message:
                gen_source(
                    [left_rule_desc], pb_file=pb_msg.pb_file, pb_msg=pb_msg, loader=None
                )
        if rule_mode == "l":
            for pb_msg in pb_set.generate_message:
                for loader in pb_msg.loaders:
                    gen_source(
                        [left_rule_desc],
                        pb_file=pb_msg.pb_file,
                        pb_msg=pb_msg,
                        loader=loader,
                    )
        if rule_mode == "f":
            for file_path in pb_set.pb_files:
                if file_ignore_packages and file_path in file_ignore_packages:
                    continue
                if file_include_rules:
                    selected = False
                    for rule in file_include_rules:
                        if rule.match(file_path):
                            selected = True
                            break
                    if not selected:
                        continue
                if file_exclude_rules:
                    selected = True
                    for rule in file_exclude_rules:
                        if rule.match(file_path):
                            selected = False
                            break
                    if not selected:
                        continue
                gen_source(
                    [left_rule_desc],
                    pb_file=pb_set.pb_files[file_path],
                    pb_msg=None,
                    loader=None,
                )

    del temp_dir_holder

    if LOCAL_WOKER_POOL is not None:
        LOCAL_WOKER_POOL.shutdown(wait=True)
    for future in concurrent.futures.as_completed(LOCAL_WOKER_FUTURES):
        future_data = LOCAL_WOKER_FUTURES[future]
        try:
            future_result = future.result()
            if future_result is not None and future_result != 0:
                ret = 1
        except Exception as e:
            print_exception_with_traceback(
                e, "generate file {0} failed.", future_data["output_file"]
            )
            ret = 1
    sys.exit(pb_set.failed_count)


if __name__ == "__main__":
    main()
