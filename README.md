# xres-code-generator

## Custom rule

* Globale template: ```g:<template path>:<output path>```
    > Example: ```g:input.h.mako:input.generated.h```

* Field template: ```f:<header template path>:<select field regex>:<output path rule>```
    > Example: ```f:input.h.mako:CSMsg.mcs_.*_req:input.generated.${xpath_node.get_name().lower()}.h```