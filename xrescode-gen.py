#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import stat
import sys
import codecs
import shutil
import sysconfig
import re

script_dir = os.path.dirname(os.path.realpath(__file__))


class MakoModuleTempDir:
    def __init__(self, prefix_path):
        import tempfile
        if not os.path.exists(prefix_path):
            os.makedirs(prefix_path)
        self.directory_path = tempfile.mkdtemp(suffix='',
                                               prefix='',
                                               dir=prefix_path)

    def __del__(self):
        if self.directory_path is not None and os.path.exists(
                self.directory_path) and os.path.isdir(self.directory_path):
            shutil.rmtree(self.directory_path, ignore_errors=True)
            self.directory_path = None


if sys.platform == 'win32':

    def test_windows_abs_path(paths):
        if len(paths) != 2:
            return False
        if len(paths[0]) != 1:
            return False
        return paths[1][0:1] == '/' or paths[1][0:1] == '\\'


def decode_rule(pattern):
    mode = None
    input = None
    output = None
    rules = pattern.split(':')
    if len(rules) == 1:
        input = rules[0]
        return mode, input, output
    # D: Drive Name
    # F: File Path Without Drive
    # M: Mode
    if len(rules[0]) == 0:
        if sys.platform == 'win32':
            if len(rules) > 2 and test_windows_abs_path(rules[1:3]):
                # :D:\\F
                input = ':'.join(rules[1:3])
                if len(rules) > 3:
                    # :D:\\F:D:\\F
                    output = ':'.join(rules[3:])
            else:
                # :F
                input = rules[1]
                if len(rules) > 2:
                    # :F:D:\\F
                    output = ':'.join(rules[2:])
        else:
            input = rules[1]
            if len(rules) > 2:
                output = rules[2]
        return mode, input, output
    elif len(rules[0]) > 1:
        input = rules[0]
        output = ':'.join(rules[1:])
        return mode, input, output
    if sys.platform == 'win32':
        if test_windows_abs_path(rules[0:2]):
            # D:\\F
            input = ':'.join(rules[0:2])
            if len(rules) > 2:
                # D:\\F:[D:\\]F
                output = ':'.join(rules[2:])
        elif len(rules) > 2 and test_windows_abs_path(
                rules[1:3]) and os.path.exists(rules[0]):
            # F:D:\\F
            input = rules[0]
            output = ':'.join(rules[1:3])
        else:
            mode = rules[0].lower()
            if len(rules) == 2:
                # M:F
                input = rules[1]
            elif test_windows_abs_path(rules[1:3]):
                # M:D:\\F
                input = ':'.join(rules[1:3])
                if len(rules) > 3:
                    # M:D:\\F:[D:\\]F
                    output = ':'.join(rules[3:])
            else:
                # M:F
                input = rules[1]
                if len(rules) > 2:
                    # M:F:[D:\\]F
                    output = ':'.join(rules[2:])
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
        add_package_bin_path = os.path.join(path, "bin")
        if os.path.exists(add_package_bin_path):
            if sys.platform.lower() == "win32":
                os.environ[
                    "PATH"] = add_package_bin_path + ";" + os.environ["PATH"]
            else:
                os.environ[
                    "PATH"] = add_package_bin_path + ":" + os.environ["PATH"]

        add_package_lib_path = os.path.join(
            path,
            "lib",
            "python{0}".format(sysconfig.get_python_version()),
            "site-packages",
        )
        if os.path.exists(add_package_lib_path):
            append_paths.append(add_package_lib_path)

        add_package_lib64_path = os.path.join(
            path,
            "lib64",
            "python{0}".format(sysconfig.get_python_version()),
            "site-packages",
        )
        if os.path.exists(add_package_lib64_path):
            append_paths.append(add_package_lib64_path)

        add_package_lib_path_for_win = os.path.join(path, "Lib",
                                                    "site-packages")
        if os.path.exists(add_package_lib_path_for_win):
            append_paths.append(add_package_lib_path_for_win)
    append_paths.extend(sys.path)
    sys.path = append_paths


def main():
    os.environ["PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION"] = "python"
    from optparse import OptionParser
    usage = '%(prog)s -p <pb file> -o <output dir> [-i <additional template dirs>...] [-g <global templates>...] [-m <message templates>...] [other options...] [custom rules or field rules]'
    parser = OptionParser(usage)
    parser.add_option("-v",
                      "--version",
                      action="store_true",
                      help="show version and exit",
                      dest="version",
                      default=False)
    parser.add_option(
        "--global-package",
        action="store",
        help=
        "set global package name(namespace, passed as global_package into template)",
        dest="global_package",
        default='excel')
    parser.add_option("--msg-prefix",
                      action="store",
                      help="set class name prefix for each message generated",
                      dest="msg_prefix",
                      default='config_set_')
    parser.add_option("-g",
                      "--global",
                      action="append",
                      help="add global template",
                      dest="global_template",
                      default=[])
    parser.add_option(
        "-m",
        "--message",
        action="append",
        help=
        "add message template(H:<file name> for header and S:<file name> for source)",
        dest="message_template",
        default=[])
    parser.add_option(
        "-l",
        "--loader",
        action="append",
        help=
        "add loader template(H:<file name> for header and S:<file name> for source)",
        dest="loader_template",
        default=[])
    parser.add_option(
        "-f",
        "--file",
        action="append",
        help=
        "add file template(H:<file name> for header and S:<file name> for source)",
        dest="file_template",
        default=[])
    parser.add_option(
        "--file-ignore-package",
        action="append",
        help="ignore file in of packages",
        dest="file_ignore_package",
        default=[])
    parser.add_option(
        "--file-include",
        action="append",
        help="select only file name match the include rule(by regex)",
        dest="file_include_rule",
        default=[])
    parser.add_option(
        "--file-exclude",
        action="append",
        help="skip file name match the exclude rule(by regex)",
        dest="file_exclude_rule",
        default=[])
    parser.add_option(
        "--file-include-well-known-types",
        action="store_true",
        help="generate file templates for well known types",
        dest="file_include_well_known_types",
        default=False)
    parser.add_option(
        "--file-include-well-known-type",
        action="append",
        help="generate file templates only for included well known types",
        dest="file_include_well_known_type",
        default=[])
    parser.add_option(
        "--file-exclude-well-known-type",
        action="append",
        help="generate file templates for well known types but exclude some of them",
        dest="file_exclude_well_known_type",
        default=[])
    parser.add_option(
        "--set",
        action="append",
        help="set custom variables for rendering templates.",
        dest="set_vars",
        default=[],
    )
    parser.add_option("-p",
                      "--pb",
                      action="append",
                      help="set pb file path",
                      dest="pb",
                      default=[])
    parser.add_option("--pb-exclude-file",
                      action="append",
                      help="ignore pb file pattern(regex)",
                      dest="pb_exclude_file",
                      default=[])
    parser.add_option("--pb-exclude-package",
                      action="append",
                      help="ignore pb package pattern(regex)",
                      dest="pb_exclude_package",
                      default=[])
    parser.add_option("-o",
                      "--output-dir",
                      action="store",
                      help="set output directory",
                      dest="output_dir",
                      default=None)
    parser.add_option("-i",
                      "--input-dir",
                      action="append",
                      help="add tempalte directory",
                      dest="input_dir",
                      default=[])
    parser.add_option("--proto-v3",
                      action="store_true",
                      help="set proto v3 mode",
                      dest="proto_v3",
                      default=False)
    parser.add_option("-t",
                      "--tag",
                      action="append",
                      help="just generate message for tags",
                      dest="tags",
                      default=[])
    parser.add_option("-e",
                      "--exclude-tags",
                      action="append",
                      help="do not generate message for tags",
                      dest="exclude_tags",
                      default=[])
    parser.add_option(
        "-c",
        "--custom-group",
        action="append",
        help=
        "add custom group with format 'NAME:FILE_NAME'(example: custom_config_group:custom_group_fields.h.mako)",
        dest="custom_group",
        default=[])
    parser.add_option("--pb-include-prefix",
                      action="store",
                      help="set include prefix of generated protobuf header",
                      dest="pb_include_prefix",
                      default="")
    parser.add_option("--print-output-file",
                      action="store_true",
                      help="print output file list but generate it",
                      dest="print_output_file",
                      default=False)
    parser.add_option(
        "--no-overwrite",
        action="store_true",
        help="do not overwrite output file if it's already exists.",
        dest="no_overwrite",
        default=False)
    parser.add_option("--quiet",
                      action="store_true",
                      help="do not show the detail of generated files.",
                      dest="quiet",
                      default=False)
    parser.add_option("--encoding",
                      action="store",
                      help="set encoding of output file(default: utf-8-sig).",
                      dest="encoding",
                      default='utf-8-sig')
    parser.add_option(
        "--shared-outer-type",
        action="store",
        help=
        "set common outer type(default: org.xresloader.pb.xresloader_datablocks).",
        dest="shared_outer_type",
        default='org.xresloader.pb.xresloader_datablocks')
    parser.add_option("--shared-outer-field",
                      action="store",
                      help="set common outer type(default: data_block).",
                      dest="shared_outer_field",
                      default='data_block')
    parser.add_option(
        "--add-path",
        action="append",
        help=
        "add path to python module(where to find protobuf,six,mako,print_style and etc...)",
        dest="add_path",
        default=[],
    )
    parser.add_option(
        "--add-package-prefix",
        action="append",
        help=
        "add path to python module install prefix(where to find protobuf,six,mako,print_style and etc...)",
        dest="add_package_prefix",
        default=[],
    )

    (options, left_args) = parser.parse_args()

    if options.version:
        print('1.1.0')
        sys.exit(0)

    def print_help_msg(err_code):
        parser.print_help()
        sys.exit(err_code)

    if options.output_dir is None or options.pb is None:
        print_help_msg(1)

    prepend_paths = []
    if options.add_path:
        prepend_paths.extend([x for x in options.add_path])
    sys.path.append(os.path.join(script_dir, 'xrescode-utils'))
    sys.path.append(os.path.join(script_dir, 'pb_extension'))
    prepend_paths.extend(sys.path)
    sys.path = prepend_paths
    add_package_prefix_paths(options.add_package_prefix)

    template_paths = options.input_dir
    template_paths.append(os.path.join(script_dir, 'pb_extension'))
    template_paths.append(os.path.join(script_dir, 'xrescode-utils'))
    template_paths.append(os.path.join(script_dir, 'template'))

    pb_exclude_files = [re.compile(rule) for rule in options.pb_exclude_file]
    pb_exclude_packages = [re.compile(rule) for rule in options.pb_exclude_package]

    # parse pb file
    import pb_loader
    pb_set = pb_loader.PbDescSet(options.pb,
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
                       pb_exclude_packages=pb_exclude_packages)
    
    for custom_var in options.set_vars:
        key_value_pair = custom_var.split("=")
        if len(key_value_pair) > 1:
            pb_set.set_custom_variable(key_value_pair[0].strip(), key_value_pair[1].strip())
        elif key_value_pair:
            pb_set.set_custom_variable(key_value_pair[0].strip(), "")

    for cg in options.custom_group:
        name_idx = cg.find(":")
        if name_idx > 0 and name_idx < len(cg):
            pb_set.add_custom_blocks(cg[0:name_idx], cg[name_idx + 1:])
    # render templates
    from mako.template import Template
    from mako.lookup import TemplateLookup
    from mako.runtime import supports_caller

    temp_dir_holder = MakoModuleTempDir(
        os.path.join(
            script_dir,
            '.mako_modules-{0}.{1}.{2}'.format(sys.version_info[0],
                                               sys.version_info[1],
                                               sys.version_info[2])))
    make_module_cache_dir = temp_dir_holder.directory_path

    def gen_source(list_container, pb_file=None, pb_msg=None, loader=None):
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

            source_template_dir = os.path.realpath(
                os.path.dirname(source_template))
            lookup_dirs = [source_template_dir]
            lookup_dirs.extend(template_paths)
            project_lookup = TemplateLookup(
                directories=lookup_dirs,
                module_directory=make_module_cache_dir)
            source_tmpl = project_lookup.get_template(
                os.path.basename(source_template))
            suffix_pos = source_template.rfind('.')

            output_dir = os.getcwd()
            if options.output_dir is not None:
                output_dir = options.output_dir
                if not os.path.exists(options.output_dir):
                    os.makedirs(options.output_dir)
                else:
                    os.chmod(options.output_dir,
                             stat.S_IRWXU + stat.S_IRWXG + stat.S_IRWXO)

            if rule_output is not None:
                output_render_tmpl = Template(rule_output,
                                              lookup=project_lookup)
                output_name = output_render_tmpl.render(
                    pb_set=pb_set,
                    pb_file=pb_file,
                    pb_msg=pb_msg,
                    loader=loader,
                    output_dir=output_dir,
                    output_file=rule_output,
                    input_file=source_template,
                    msg_prefix=options.msg_prefix,
                    global_package=options.global_package)

            elif is_message_header and loader is not None:
                output_name = loader.get_cpp_header_path()
            elif is_message_source and loader is not None:
                output_name = loader.get_cpp_source_path()
            else:
                if suffix_pos < 0:
                    output_name = os.path.basename(source_template)
                else:
                    if source_template[suffix_pos + 1:].lower() == 'mako':
                        output_name = os.path.basename(
                            source_template[0:suffix_pos])
                    else:
                        output_name = os.path.basename(source_template)
                if loader is not None and loader.code:
                    suffix_pos = output_name.rfind('.')
                    if suffix_pos < 0:
                        output_name = "{0}_{1}_{2}".format(
                            output_name,
                            loader.code.package.replace(".", "::"),
                            loader.code.class_name).replace("::", "_").replace(
                                "__", "_")
                    else:
                        output_name = "{0}_{1}_{2}{3}".format(
                            output_name[0:suffix_pos],
                            loader.code.package.replace(".", "::"),
                            loader.code.class_name,
                            output_name[suffix_pos:]).replace("::",
                                                              "_").replace(
                                                                  "__", "_")

            output_name = os.path.join(options.output_dir, output_name)

            if os.path.exists(output_name):
                os.chmod(output_name,
                         stat.S_IRWXU + stat.S_IRWXG + stat.S_IRWXO)

            if options.print_output_file:
                print(output_name)
            else:
                if options.no_overwrite and os.path.exists(output_name):
                    if not options.quiet:
                        print(
                            "[XRESCODE] Ignore genarate template from {0} to {1}, already exists."
                            .format(source_template, output_name))
                else:
                    if not options.quiet:
                        print("[XRESCODE] Genarate template from {0} to {1}".
                              format(source_template, output_name))
                    render_output = source_tmpl.render(
                        pb_set=pb_set,
                        pb_msg=pb_msg,
                        pb_file=pb_file,
                        loader=loader,
                        output_dir=output_dir,
                        output_file=output_name,
                        input_file=source_template,
                        msg_prefix=options.msg_prefix,
                        global_package=options.global_package)
                    if os.path.exists(output_name):
                        f = codecs.open(str(output_name),
                                        mode='r',
                                        encoding=options.encoding)
                        if f.read() == render_output:
                            f.close()
                            continue
                        f.close()
                    elif not os.path.exists(os.path.dirname(output_name)):
                        os.makedirs(os.path.dirname(output_name))

                    codecs.open(str(output_name),
                                mode='w',
                                encoding=options.encoding).write(
                                    str(render_output))

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
        gen_source(options.message_template, pb_file=pb_msg.pb_file, pb_msg=pb_msg, loader=None)
        for loader in pb_msg.loaders:
            gen_source(options.loader_template, pb_file=pb_msg.pb_file, pb_msg=pb_msg, loader=loader)
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
            gen_source(options.file_template, pb_file=pb_set.pb_files[file_path], pb_msg=None, loader=None)

    for rule in left_args:
        if len(rule) < 2:
            sys.stderr.write(
                '[XRESCODE ERROR] Invalid custom rule {0}\n'.format(rule))
            continue
        rule_mode, rule_input, rule_output = decode_rule(rule)
        if rule_output is None:
            left_rule_desc = rule_input
        else:
            left_rule_desc = '{0}:{1}'.format(rule_input, rule_output)
        if rule_mode == "g":
            gen_source([left_rule_desc], None, None, None)
        if rule_mode == "m":
            for pb_msg in pb_set.generate_message:
                gen_source([left_rule_desc], pb_file=pb_msg.pb_file, pb_msg=pb_msg, loader=None)
        if rule_mode == "l":
            for pb_msg in pb_set.generate_message:
                for loader in pb_msg.loaders:
                    gen_source([left_rule_desc],
                                pb_file=pb_msg.pb_file,
                                pb_msg=pb_msg,
                                loader=loader)
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
                gen_source([left_rule_desc], pb_file=pb_set.pb_files[file_path], pb_msg=None, loader=None)

    del temp_dir_holder
    sys.exit(pb_set.failed_count)


if __name__ == '__main__':
    main()
