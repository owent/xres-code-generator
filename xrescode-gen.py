#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import glob
import os
import stat
import sys
import codecs
import re
import shutil
import xml.etree.ElementTree as ET

script_dir = os.path.dirname(os.path.realpath(__file__))


if __name__ == '__main__':
    from optparse import OptionParser
    usage = '%(prog)s -p <pb file> -o <output dir> [-i <additional template dirs>...] [-g <global templates>...] [-m <message templates>...] [other options...]'
    parser = OptionParser(usage)
    parser.add_option(
        "-v",
        "--version",
        action="store_true",
        help="show version and exit",
        dest="version",
        default=False)
    parser.add_option(
        "--msg-prefix",
        action="store",
        help="set class name prefix for each message generated",
        dest="msg_prefix",
        default='config_set_')
    parser.add_option(
        "-g",
        "--global",
        action="append",
        help="add global template",
        dest="global_template",
        default=[])
    parser.add_option(
        "-m",
        "--message",
        action="append",
        help="add message template(H:<file name> for header and S:<file name> for source)",
        dest="message_template",
        default=[])
    parser.add_option(
        "-p",
        "--pb",
        action="store",
        help="set pb file path",
        dest="pb",
        default=None)
    parser.add_option(
        "-o",
        "--output-dir",
        action="store",
        help="set output directory",
        dest="output_dir",
        default=[])
    parser.add_option(
        "-i",
        "--input-dir",
        action="append",
        help="add tempalte directory",
        dest="input_dir",
        default=[])
    parser.add_option(
        "--proto-v3",
        action="store_true",
        help="set proto v3 mode",
        dest="proto_v3",
        default=False)
    parser.add_option(
        "-t",
        "--tag",
        action="store",
        help="just generate message for tags",
        dest="tags",
        default=[])
    parser.add_option(
        "--pb-include-prefix",
        action="store",
        help="set include prefix of generated protobuf header",
        dest="pb_include_prefix",
        default="")
    parser.add_option(
        "--print-output-file",
        action="store_true",
        help="print output file list but generate it",
        dest="print_output_file",
        default=False)

    (options, left_args) = parser.parse_args()

    if options.version:
        print('1.0.0')
        exit(0)

    def print_help_msg(err_code):
        parser.print_help()
        exit(err_code)

    if options.output_dir is None or options.pb is None:
        print_help_msg(1)

    sys.path.append(os.path.join(script_dir, '3rd_party', 'protobuf'))
    sys.path.append(os.path.join(script_dir, '3rd_party', 'mako'))
    sys.path.append(os.path.join(script_dir, 'xrescode-utils'))
    sys.path.append(os.path.join(script_dir, 'pb_extension'))

    template_paths = options.input_dir
    template_paths.append(os.path.join(script_dir, 'pb_extension'))
    template_paths.append(os.path.join(script_dir, 'xrescode-utils'))

    # parse pb file
    from pb_loader import PbDescSet
    pb_set = PbDescSet(options.pb, tags=options.tags, msg_prefix=options.msg_prefix, 
        proto_v3=options.proto_v3, pb_include_prefix=options.pb_include_prefix)

    # render templates
    from mako.template import Template
    from mako.lookup import TemplateLookup
    from mako.runtime import supports_caller

    make_module_cache_dir = os.path.join(script_dir, '.mako_modules')
    def gen_source(list_container, pb_msg=None):
        for input_file in list_container:
            is_message_header = False
            is_message_source = False
            if pb_msg is None:
                source_template = input_file
            else:
                if input_file[0:2].lower() == "h:":
                    is_message_header = True
                    source_template = input_file[2:]
                elif input_file[0:2].lower() == "s:":
                    is_message_source = True
                    source_template = input_file[2:]
                else:
                    source_template = input_file

            source_template_dir = os.path.realpath(os.path.dirname(source_template))
            lookup_dirs = [source_template_dir]
            lookup_dirs.extend(template_paths)
            project_lookup = TemplateLookup(directories=lookup_dirs, module_directory=make_module_cache_dir)
            source_tmpl = project_lookup.get_template(
                os.path.basename(source_template))
            suffix_pos = source_template.rfind('.')

            if is_message_header:
                output_name = pb_msg.get_cpp_header_path()
            elif is_message_source:
                output_name = pb_msg.get_cpp_source_path()
            else:
                if suffix_pos < 0:
                    output_name = os.path.basename(source_template)
                else:
                    if source_template[suffix_pos + 1:].lower() == 'mako':
                        output_name = os.path.basename(source_template[0:suffix_pos])
                    else:
                        output_name = os.path.basename(source_template)
                if pb_msg is not None and pb_msg.code:
                    suffix_pos = output_name.rfind('.')
                    if suffix_pos < 0:
                        output_name = "{0}_{1}_{2}".format(output_name, pb_msg.cpp_package_prefix, 
                            pb_msg.code.class_name).replace("::", "_").replace("__", "_")
                    else:
                        output_name = "{0}_{1}_{2}{3}".format(output_name[0:suffix_pos], pb_msg.cpp_package_prefix, 
                            pb_msg.code.class_name, output_name[suffix_pos:]).replace("::", "_").replace("__", "_")
                    
            output_dir = os.getcwd()
            if options.output_dir is not None:
                output_dir = options.output_dir
                if not os.path.exists(options.output_dir):
                    os.makedirs(options.output_dir)
                else:
                    os.chmod(options.output_dir, stat.S_IRWXU + stat.S_IRWXG + stat.S_IRWXO)

                output_name = os.path.join(options.output_dir, output_name)

            if os.path.exists(output_name):
                os.chmod(output_name, stat.S_IRWXU + stat.S_IRWXG + stat.S_IRWXO)

            if options.print_output_file:
                print(output_name)
            else:
                print("Genarate template from {0} to {1}".format(source_template, output_name))
                codecs.open(output_name, mode='w', encoding='utf8').write(
                    source_tmpl.render(
                        pb_set=pb_set,
                        pb_msg=pb_msg,
                        output_dir=output_dir,
                        output_file=output_name,
                        input_file=source_template,
                        msg_prefix=options.msg_prefix
                    )
                )

    gen_source(options.global_template, None)
    for pb_msg in pb_set.generate_message:
        gen_source(options.message_template, pb_msg=pb_msg)