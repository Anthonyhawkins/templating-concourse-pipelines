# Comparison of YAML Templating Solutions for Concourse Pipelines
YAML has become the king of decleration and configuration in regards to infrastructure automation.  Tools like Salt, Ansible, Concourse, Kubernetes, etc. Use YAML to configure and or declare automation workflows.

Often in YAML configurations, one must need to template or recycle configs and or inject external data and variables into them. Unlike merging, where two sets of data are brought together to form one, templating requires the use of conditionals such as if this value exists, than this part of the config should too, etc.  These are capabilities which go beyond merging, interpolation, or overlaying.  It's this conditional (if else) and control (for each) capability which is what is experimented with here.

What sparked this experiment was a new tool on the block, at least to me, called ytt. Which looked like provided all the same controls and conditionals of jinja but provided the merging and injecting capabilities of spruce.  In addition, it understands yaml and preserves the YAML syntax of the document and might solve the indent concious workflow one must have when working with Jinja and yaml. 

The examples model a concourse pipelines repo containing various environment-based inputs, pipeline-based inputs, pipeline configs, and task configs. 

## Goals
I wanted to explore some options for templating YAML as it's something I do pretty regularly in my full time job developing concourse pipelines and automation in general. The solution I'm aiming for should meet the following requirements:
- Provide Conditional or Looping capabilities.  If / For etc. 
- Provide a way to break up and recycle yaml into parts, modules, macros etc. to be reused over and over again.
- Provide a way to easily inject Bash ENVIRONEMNT variables into the config
- Provide a way to source multiple inputs into a single template.
- Soultuon should be easy to understand and intuitive to use.  Tooling should work as expected.
- Solution should preserve the original order in output to retain readability

# Solutions Overview 
## Soluton 1 - Jinja Based
This setup is the one I was most familiar with as I've used Jinja before but always had trouble with managing indents when it came to yaml.  I used Jinja as the control to compare against ytt, which is the tool I was most curious to test and play with.
- **Jinja2:** Jinja is a text based templating languages in that it can be applied to any text-based document.
    - **PROS:** Jinja has been around for a long time, is well documented and provides a lot of capability. It's also fairly intuative to get started with, mostly because of it's great documentation and community. 
    - **CONS:** Because Jinja is a text editor it doesn't understand YAML, it just knows that it's templating text which happens to be YAML.  Because of this, as soon as Jinja exists within a document it's not longer syntatical YAML, HTML, etc. it's a j2 or jinja template. Working with indent sensitive YAML can be tricky when working with jinja.
- **yasha:** Yasha is the Python CLI tool which implements the Jinja templating engine in a handy CLI utility
    - **PROS:** Incredibly easy to use, intutive and provided features such as passing in multiple input files into one template file
    - **CONS:** Error messaging was a little robust as it seems like it's just a standard Python Exception Stack which may not be familiar unless you work with Python a lot. 

## Solution 2 - YTT Based
ytt looked really promising to me.  I really got excited when I saw the if and for loop capability as that's a feature I've only seen in Jinja or other templating engines but missing from tools like spruce.  To say I was disapointed was an understatement. I felt the tool is there but it has a really steep learning curve as it simply never seemed to work the way I expected to.  

It's ability to read values from the environment seemed like an afterthought which was actually addressed later in a PR.  Unlike spruce or jinja where you can declare which values are ENV variables right in the template, you must pass these all in via the CLI as args or a PREFIX which is cumbersome, in my opinion.  I also felt the pain required to pass in multiple inputs like I could with jinja to be very frustrating.  Overall, I felt the tool was so cumbersome to use that I ended up using spruce before and after the execution of ytt to one, prepare inputs, and then lastly to inject and ENV variables from the environment.  Overall this wasn't a terrible solution which I think utilized the best capabilities of each tool.

- **ytt**:  ytt is rather new and is a templating and overlay utility which was built specifically for templating and overlaying YAML data. It's most popular within the kubernetes community.
    - **PROS:** ytt Understands YAML. Because of this, it respects indentation and lives within comments, ensuring the document is still syntactically YAML.
    - **CONS:** ytt, to me at least, was extreamly unintuitive to use and get started with.  The documentation didn't really provide a complete picture of what the command line call was which produced a specific output.  I found all the various importing of modules to be cumbersome and how I expcted the tool to work was not always the case.  It's community and online resources such as videos, tutorials etc. were sparese at best.  It's overlay features was so unintuative 
- **spruce:** Spruce is a pivotal developed YAML and JSON merging tool which works really well at merging two sets of data into one.
    - **PROS:** Dead simple to get started with.  Point it at two yaml files and merge away.  It also provides for a great set of operators.
    - **CONS:** Easy to learn, but hard to master some of the more advanced operators.  It's also hard looking at a spruce template and then understanding where data is being sourced from, unless you look at spruce command used to generate it. Spruce also does not preserve the ordering of the yaml when outputting, making comprehending the final result pretty disorienting, especially when viewing concourse pipelines configs. 

# Use Cases
## Passing Inputs into a Template
This is the bare bones of what you need a template engine to do. I have a template I want to use more than once, and I have some variables I want to pass in to generate a final result.
### **How YTT does it**
ytt requires you to use a bit of boiler-plate for all files used. One of which is specifying which yaml file is going to be the inputs and which yaml file is going load said inputs.

For example here is how I would define the inputs yaml, called the data values file in ytt speak.
```
#@data/values
---
foo: bar
biz: baz
```
and to use said inputs
```
#@ load("@ytt:data", "data")
some_key: #@ data.values.foo
```

The gotcha is ok what about if I have *two* or more inputs? Well Ytt kinda breaks down here and you need to import another module called the overlay module.  And that second file needs yet another new boiler-plate header.

```
#@ load("@ytt:overlay", "overlay")
#@data/values
---
foo: biz
...
```
What was also interesting is that the keys of the first and second file had to be the same as it's really not a second input file, but an overlay file. You then start adding annotation everywhere to tell ytt how to merge and combine the two sets of inputs.  
```
...
#@overlay/match missing_ok=True
zaz: x
```

This behaviour was so hard to wrap my head around I ultimately relieved ytt of it's input file duties and brought in spruce to help merge and prepare a single data values file.  But... Because ytt lives in comments, the boiler plate needed to be added at the end or start of the file like such.
```
echo "#@data/values" > data_vaules.yml
echo "---" >> data_vaules.yml

spruce merge inputs_one.yml inputs_two.yml >> data_vaules.yml

ytt -f data_vaules.yml -f template.yml

```
The result, which I found much easier than ytt and If I wanted more power I could just start using spruce operators to help merge the inputs together more surgically. 
```
#@data/values
---
foo: biz
biz: baz
zaz: x
```

### **How Jinja and yasha does it**
No boiler plate, easy to understand and implement.  

Input One
```
foo: bar
```

Input Two
```
bin: baz
```

Template
```
some_key: {{ bin }}
other_key: {{ foo }}
```

Yasha command

`yasha -v input_one.yml -v input_two.yml template.yml`

Result
```
some_key: baz
other_key: bar
```
The only issue is that you don't know if `bin` or `foo` is sourced from input one or two.  A way to solve this is to just to add a top-level key the same name as the file. This can create a namespace of sorts for your inputs and protect against unwanted merges but, this is completely optional and is up to you and the conventions you want to establish.

Input One
```
input_one: 
    foo: bar
```

Template
```
some_key: {{ bin }}
other_key: {{ input_one.foo }}
```

## Conditionals If Else
Let's say you want to check if this config applies to a certain environment. i.e. only apply if environment is site-a, site-b, or site-c.
### **YTT**
In ytt this is pretty easy to do. Note, this is still valid yaml. ytt lives in comments.
```
#@ if data.values.environment in ['site-a', 'site-b', 'site-c']:
enable_x: true
#@ end
```
### **Jinja**
same as in jinja, Note, this is NOT valid yaml.
```
{% if environment in ['site-a', 'site-b', 'site-c'] %}
enable_x: true
{%- endif %}
```

## For Loops
The ultimate test I like to use for looping is iterating over keys and values in a map/dictionary. 

Given the following input...
```
tiles:
  ert:
    product: cf
    mirror: pivnet
    ver: '3\.1\.1'
    environments:
    - site-a
    - site-c
  mysql-4.3:
    product: p-mysql
    mirror: pivnet
    ver: '4\.3\..*'
    dependencies:
    - ert
    environments:
    - site-a
  redis-4:
    product: p-redis
    mirror: pivnet
    ver: '4\.3\..*'
    dependencies:
    - ert
    environments:
    - site-b
    - site-a
```
### **YTT**
You would think the key `tiles` would be a map when you go to operate on it. But it's actually a `struct` which you want nothing to do with if you simply want to template yaml.  So... to get around this you need to add some more boilerplate
```
#@ load("@ytt:struct", "struct")
```
ok good, now I need to simply decode this struct into a map...
```
#@ tiles = struct.decode(data.values.tiles)
```

Now I can iterate over it...
```
#@ for tile in tiles:
- name: #@ "product-" + tile
  type: pivnet
  source:
    api_token: pivnet_token
    product_slug: image-slug
    product_version: #@ tiles[tile]['ver']
#@ end
```

This is a prime example of I expected the tool to work one way but ended up tripping over it and stack overflowing my way to a solution.  This was pretty much most of how working in YTT went. 

### **Jinja**
Because Jinja is python under the hood, it's the same as in python.  Easy.
```
{% for tile, config in tiles.items() %}
- name: {{ "product-" + tile }}
  type: pivnet
  source:
    api_token: pivnet_token
    product_slug: image-slug
    product_version: {{ config['ver'] }}
{% endfor %}
```

## Includes / Macros / Functions
Take a bit of yaml which you plan on using over and over again, store it in an external file and import it into any template which you need to use it in.  

Given the following external yaml
```
params:
  ENVIRONMENT: ENVIRONMENT
  SECRETS_PASS: secrets_pass
  NUM_NODES: num_nodes
inputs:
- name: do_bar
- name: pipelines-repo
- name: secrets-repo
outputs:
- name: do_bar
platform: linux
image_resource:
  type: docker-image
  source:
    repository: lab/python-image
    username: docker_user
    password: docker_password
run:
  path: echo
  args: ["Hello, world!"]
  ```

and you want to include it here in your template.
```
  - task: do_foo 
    config:
      <YAML GOES HERE>
```

### **YTT**
First thing you need to do is wrap your include in a ytt function.

```
#@ load("@ytt:data", "data")
#@ def do_bar():
params:
  ENVIRONMENT: ENVIRONMENT
  SECRETS_PASS: secrets_pass
  NUM_NODES: num_nodes
inputs:
- name: do_bar
- name: pipelines-repo
- name: secrets-repo
outputs:
- name: do_bar
platform: linux
image_resource:
  type: docker-image
  source:
    repository: lab/python-image
    username: docker_user
    password: docker_password
run:
  path: echo
  args: ["Hello, world!"]
#@ end
```

and then rename the file to a `.lib.yml`... 

`mv task.yml task.lib.yml`

Now load it into your template ( this would normally be a the top of your file)
then you can call it.  This will insert the task.yml as a childer under `config`.  
```
#@ load("do_bar/task.lib.yml", "do_bar")

  - task: do_foo 
    config:
      config: #@ do_bar()
```
What's really nice about this is you don't have to think about indenting which is great when working with concourse nested tasks, or yaml in general. Because YTT understand yaml, it knows how to properly insert the data.
```
  - task: do_bar 
    config: #@ do_bar()
    on_failure:
      task: do_baz
      config: #@ do_baz()
      on_failure:
        task: do_baz
        config: #@ do_baz()
```

### **Jinja** 
Jinja works in a similar way as ytt. Declare a macro/function around your external yaml, import it, then use it.

```
{% macro do_bar() -%}
params:
  ENVIRONMENT: ENVIRONMENT
  SECRETS_PASS: secrets_pass
inputs:
- name: do_bar
- name: pipelines-repo
- name: secrets-repo
outputs:
- name: do_bar
platform: linux
image_resource:
  type: docker-image
  source:
    repository: lab/python-image
    username: docker_user
    password: docker_password
run:
  path: echo
  args: ["Hello, world!"]
{%- endmacro %}
```

```
{% from "do_bar/task.yml" import do_bar with context %}


  - task: do_bar 
    config:
      {{ do_bar() | indent(6)}}
```

Here is Jinja's biggest weakness. Because ths tool is a general purpose text-templating tool, it doesn't know or care about if it is in a yaml document. If the `| indent(6)` filter was not used, the include would be all the way left-aligned which is not what we want.  This becomes an even bigger pain when dealing with nested tasks as you need to count the indent spaces.  
```
  - task: do_foo 
    config:
      {{ do_foo() | indent(6)}}
    on_failure:
      task: do_foo
      config:
        {{ do_bar() | indent(8)}}
      on_failure:
        task: do_baz
        config:
          {{ do_baz() | indent(10)}}
```
A trick I found was to place my cursor at the point I wanted the indent to be, then look at the `col` value (char position from left to right) at the bottom of the code-editor.  The indent was always `col-1`.  This made it workable, and if you don't have an editor which displays `col` position, you'd have to count for each indented block.  It was this reason, alone, that I looked at YTT to overcome this problem.

## Environment Variables
A lot of times, the values which need to be injected into a template don't come from an input file, but instead, the runtime environment which the yaml will reside in.  In terms of a concourse pipeline, the Environment variable for the target environment will need to be passed, or sensitive values such as secrets.  

### **YTT**
As mentioned earlier, YTT's implementation of environment variables was an after-thought as I could see the original GitHub issue where someone had this problem, then a PR was created to address it.  The solution is to prefix all your environment variables with a common PREFIX such as `YTT_foo=bar`.  Then this variable ONLY can be used to overide an existing data values value such as 
```
#@data/values
---
foo: some_throw_away_value
```
Then you need to pass the data values file off to the template like usual.

This approach was so convoluted to me I didn't even bother trying it out, because a lot of your environment variables are already set by outside scripts or stored in other bash files.  Renaming them all to fit into YTT would be a mess, and trying to walk through a yaml config and figuring out if a value should come from the environment or not would be a complete mess.

The solution I went with was to again delegate this task to spruce as in spruce all you need to go is just do.
```
foo: (( grab $FOO ))
```
That's it. 

Because spruce can live inside the ytt files, anywhere I needed an environment variable, I would just use spruce on the resulting yaml file. The resulting ytt solution using spruce for interpolation for ytt inputs and the output from ytt results in something like this.

```
#!/bin/bash

pipeline=$1
environment=$2

working_dir=/workspaces/ytt-lab/ytt-example

#
# Use Spruce to Merge and Create Pipeline Inputs File 
# known as data.values file to ytt
#

echo "#@data/values" > data_vaules.yml
echo "---" >> data_vaules.yml

spruce merge \
$working_dir/pipeline-vars/defaults.yml \
$working_dir/pipeline-vars/$pipeline.yml \
>> data_vaules.yml

#
# Use YTT to combine data.values with pipeline config and task configs.
#
ytt -f $working_dir/pipelines/$pipeline.yml \
    -f $working_dir/tasks/ \
    -f data_vaules.yml > pipeline.spruce.yml

#
# Use spruce again to inject ENV variables and finalize config
#

#spruce
spruce merge pipeline.spruce.yml > pipeline.yml

#
# Run Fly Set pipeline 
#
```
This worked great, EXCEPT, that if you care about the order of your yaml, the bad news is spruce does not.  For example, if you need to interpolate a bunch of variables using spruce on a concourse pipeline config, the resulting output would be a scramble.  Like resources at the top? Too bad, spruce put them at the bottom.  Like the `task` key for a task item within a plan to be the first key? Too bad, spruce made that the third key after `config`. 


# My Thoughts
ytt had great promises.  I really, really, really wanted to like it.  I thought the idea of hiding the templating engine within comments was a great idea.  I also was excited abou the loops, ifs etc. the things I liked from Jinja but were not available in spruce.  I loved that it was yaml aware, and understood indenting.

However, the tool is just plain convoluted.  I spent a few long nights trying to fight the tool in regards to multiple input files, figuring out what boiler-plate needed to be where, looking at a yaml hash, it loading it as a struct, and then I'd have to decode it back to a map to iterate, etc. Counting indents in Jinja is nothing compared to all the pain in the asss gotcha's I had to work through with ytt. I didn't even get to all the features and capabilities of the tool becasue the basics were just too painful to get started with.

Even if I learned this tool, even if I wrapped my head around it and have it click with me one day, it's not the right tool for me. It's not just what I have to use, it's something I need to consider as a tool my team can use and have it be easy to write and easy and understand days later. 

The perfect yaml templating tool has yet to be created, but for now Jinja comes pretty close, and if you need a little extra bit of merge power, you can always spruce it up.