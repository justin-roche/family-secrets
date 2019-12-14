#!/usr/bin/env ruby

################################# Data Source

@people = Array[ 
			Hash[
				"name" => "Grandfather",
		 		"parents" => Array[],  
		 		"children" => Array[],
			],
			Hash[
				"name" => "Grandmother",
		 		"parents" => Array[],  
		 		"children" => Array[],
			],
			Hash[
				"name" => "Father",
		 		"parents" => Array["Grandfather", "Grandmother"],  
		 		"children" => Array[],
			],
			Hash[
				"name" => "Uncle",
		 		"parents" => Array["Grandfather", "Grandmother"],  
		 		"children" => Array[],
			],
			Hash[
				"name" => "Mother",
		 		"parents" => Array[],  
		 		"children" => Array[],
			],
			Hash[
				"name" => "Self",
		 		"parents" => Array["Father","Mother"],  
		 		"children" => Array[],
			]
		]

################################# Model Creation

def build_model (hash_collection)

	object_collection = build_object_collection(hash_collection)
	objects = link_objects(object_collection)
end

def build_object_collection(hash_collection)

	object_collection = Array.new

	hash_collection.each do |item| #key,value pair

		name = item["name"]
		parents = item["parents"]
		children = item["children"]

		p = Person.new(name, parents, children)
		object_collection << p
	end

	object_collection
end

class Person
	attr_accessor :name, :parents, :children

	def initialize (name, parents, children)
		@name = name
		@parents = parents 
		@children = children 
	end
end

def link_objects(object_collection)

	master_node = Person.new("master", Array[], Array[]) #all attributes set to nil

	object_collection.each do |item|

		if item.parents.length == 0 
			item.parents[0] = master_node
			master_node.children << item 
		else
			p1 = object_collection.select {|candidate| candidate.name === item.parents[0]}
			p2 = object_collection.select {|candidate| candidate.name === item.parents[1]}
			p1 = p1[0]
			p2 = p2[0]

			item.parents = [p1, p2]
			p1.children << item unless p1.children.any?{|cs| cs.name === item.name}
			p2.children << item unless p2.children.any?{|cs| cs.name === item.name}
		end
	end

	object_collection.unshift(master_node)
	object_collection 
end

################################# Git Utilities

def git(command)
	command = "git " + command
	`#{command}`
end

def prompt_delete
	%x[rm -rf .git]
	%x[rm promptfile]
	print "deleted"
end

def init_git
	%x[touch promptfile]
	git("init")
	make_commit("god")
end

def make_branch(source_name, target_name)
	git "checkout #{source_name}"
	git "checkout -b #{target_name}_branch"
	make_commit(target_name)
	git "tag birthof_#{target_name}"

end

def make_merge(branch_1, branch_2, new_branch)
	git "checkout #{branch_1}_branch"
	git "checkout -b #{new_branch}_branch"
	git "merge #{branch_2}_branch"
	make_commit(new_branch)
	git "tag birthof_#{new_branch}"

	## prep branches for further additions
	git "checkout #{branch_1}_branch"
	make_commit(branch_1)
	git "checkout #{branch_2}_branch"
	make_commit(branch_2)
end

def append_master(name)
	git "checkout Master"
	git "checkout -b #{name}_branch"
	make_commit(name)
	git "tag birthof_#{name}"
end

def make_commit(name)
	 %x[echo "track this" >> promptfile]
	 git "add promptfile"
	 git "commit -m #{name}_commit"
end

def branchexists(name)
	name = name + "_branch"
	if `git branch --list #{name} ` == ""
		false
	else
		true
	end
end

################################# View Creation

def populate_descendants(master)
	
	q = Array[]

	## Populate all immediate descendants of master

	master.children.each do |child|
		append_master(child.name)

		child.children.each do |newchild|
			q << newchild unless q.any?{|person| person.name == newchild.name}
		end
	end

	## Breadth-first populate others

	while q.length > 0
		t = q.shift
		p1 = t.parents[0].name
		p2 = t.parents[1].name
		if branchexists(p1) && branchexists(p2) ##check that both parents already exist
			make_merge(t.parents[0].name, t.parents[1].name,t.name)
			t.children.each do |newchild|
				q << newchild unless q.any?{|person| person.name === newchild.name} ##avoid adding duplicates to q
			end
		end
	end
end

################################# View Editing

################################# Terminal Utilities
def prompt(message)
	print message
	name = gets.chomp
end

################################# Execution

if ARGV[0] == "del"
	prompt_delete
else
	init_git
	objects = build_model(@people)
	populate_descendants(objects[0]) ##send in master_node	
end







