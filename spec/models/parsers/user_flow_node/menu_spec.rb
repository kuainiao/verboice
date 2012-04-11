require 'spec_helper'

module Parsers
  module UserFlowNode
    describe Menu do

      let(:app) { self }
      it "should compile to a verboice equivalent flow" do
        menu = Menu.new app, 'id' => 27,
          'type' => 'menu',
          'name' => 'Menu number one',
          'explanation_message' => {
            "name" => "Some explanation message",
            "type" => "record",
            "file" => "file.wav",
            "duration" => 5
          },
          'options_message' => {
            "name" => "Some options message",
            "type" => "record",
            "file" => "file.wav",
            "duration" => 5
          },
          'timeout'=> 20,
          'number_of_attempts' => 3,
          'invalid_message' => {
            "name" => "An invalid key was pressed",
            "type" => "record",
            "file" => "file.wav",
            "duration" => 5
          },
          'end_call_message' => {
            "name" => "This call will end now",
            "type" => "record",
            "file" => "file.wav",
            "duration" => 5
          },
          'options' => [
            {
              'description' => 'foo',
              'number' => 4,
              'next' => 10
            },
            {
              'description' => 'bar',
              'number' => 6,
              'next' => 14
            },
            {
              'description' => 'zzz',
              'number' => 2,
              'next' => 5
            }
          ]
        menu_2 = Menu.new app, 'id' => 10, 'type' => 'menu',
          'name' => 'Menu number two',
          'explanation_message' => {
            "name" => "Second explanation message",
            "type" => "record",
            "file" => "file.wav",
            "duration" => 5
          }, 'options_message' => {}, 'end_call_message' => {}, 'invalid_message' => {}
        menu_3 = Menu.new app, 'id' => 14, 'type' => 'menu',
          'explanation_message' => {
            "name" => "Third explanation message",
            "type" => "record",
            "file" => "file.wav",
            "duration" => 5
          }, 'options_message' => {}, 'end_call_message' => {}, 'invalid_message' => {}
        menu_4 = Menu.new app, 'id' => 5, 'type' => 'menu',
          'explanation_message' => {
            "name" => "Fourth explanation message",
            "type" => "record",
            "file" => "file.wav",
            "duration" => 5
          }, 'options_message' => {}, 'end_call_message' => {}, 'invalid_message' => {}

        menu.solve_links_with [ menu_2, menu_3, menu_4 ]

        menu.equivalent_flow.should eq([
          { say: 'Some explanation message' },
          { assign: { name: 'attempt_number', expr: '1' }},
          { assign: { name: 'end', expr: 'false' }},
          { :while => { :condition => 'attempt_number <= 3 && !end', :do => [
            {
              capture: {
                timeout: 20,
                say: 'Some options message'
              }
            },
            {
              :if => {
                :condition => "digits == 4",
                :then => [
                  { trace: {
                    :application_id => 1,
                    :step_id => 27,
                    :store => '"User pressed: " + digits'
                  }},
                  { say: 'Second explanation message' },
                  { assign: { name: 'end', expr: 'true' }}
                ],
                :else => {
                  :if => {
                    :condition => "digits == 6",
                    :then => [
                      { trace: {
                        :application_id => 1,
                        :step_id => 27,
                        :store => '"User pressed: " + digits'
                      }},
                      { say: 'Third explanation message' },
                      { assign: { name: 'end', expr: 'true' }}
                    ],
                    :else => {
                      :if => {
                        :condition => "digits == 2",
                        :then => [
                          { trace: {
                            :application_id => 1,
                            :step_id => 27,
                            :store => '"User pressed: " + digits'
                          }},
                          { say: 'Fourth explanation message' },
                          { assign: { name: 'end', expr: 'true' }}
                        ],
                        :else => {
                          :if => {
                            :condition => "digits != null",
                            :then => [
                              { say: "An invalid key was pressed" },
                              { trace: {
                                :application_id => 1,
                                :step_id => 27,
                                :store => '"Invalid key pressed"'
                              }}
                            ],
                            :else => [
                              { trace: {
                                :application_id => 1,
                                :step_id => 27,
                                :store => '"No key was pressed. Timeout."'
                              }}
                            ]
                          }
                        }
                      }
                    }
                  }
                }
              }
            },
            { assign: { name: 'attempt_number', expr: 'attempt_number + 1' }}
          ]}},
          {
            :if => {
              :condition => 'attempt_number > 3 && !end',
              :then => [
                { say: 'This call will end now' },
                { trace: {
                  :application_id => 1,
                  :step_id => 27,
                  :store => '"Missed input for 3 times."'
                }}
              ]
            }
          }
        ])

      end

      it "should compile to a minimum verboice equivalent flow" do
        menu_1 = Menu.new app, 'id' => 27, 'type' => 'menu', 'explanation_message' => {}, 'options_message' => {}, 'end_call_message' => {}, 'invalid_message' => {}
        menu_1.equivalent_flow.should eq([])

        menu_3 = Menu.new app, 'id' => 27, 'type' => 'menu',
          'explanation_message' => {'name' => 'foobar'},
          'invalid_message' => {'name' => 'invalid key pressed'},
          'end_call_message' => {'name' => 'Good Bye'},
          'options_message' => {},
          'options' => [
            {
              'description' => 'foo',
              'number' => 4,
              'next' => 10
            }
          ]
        menu_4 = Menu.new app, 'id' => 10, 'type' => 'menu', 'explanation_message' => {'name' => 'asdf'}, 'options_message' => {}, 'end_call_message' => {}, 'invalid_message' => {}
        menu_3.solve_links_with [ menu_4 ]

        menu_3.equivalent_flow.should eq([
          { say: 'foobar' },
          {:assign=>{:name=>"attempt_number", :expr=>"1"}},
          {:assign=>{:name=>"end", :expr=>"false"}},
          {:while=> {
            :condition=>"attempt_number <= 3 && !end",
            :do=> [
              {:capture=>{:timeout=>5}},
              {
                :if=> {
                  :condition=>"digits == 4",
                  :then=>[
                    { :trace=> {
                      :application_id=>1,
                      :step_id=>27,
                      :store=>"\"User pressed: \" + digits"
                    }},
                    { :say=>"asdf" },
                    { :assign=> { :name=>"end", :expr=>"true" }}
                  ],
                  :else => {
                    :if => {
                      :condition => "digits != null",
                      :then => [
                        { say: "invalid key pressed" },
                        { trace: {
                          :application_id => 1,
                          :step_id => 27,
                          :store => '"Invalid key pressed"'
                        }}
                      ],
                      :else => [
                        { trace: {
                          :application_id => 1,
                          :step_id => 27,
                          :store => '"No key was pressed. Timeout."'
                        }}
                      ]
                    }
                  }
                }
              },
              {:assign=>{:name=>"attempt_number", :expr=>"attempt_number + 1"}}
            ]
          }},
          {
            :if=> {
              :condition => "attempt_number > 3 && !end",
              :then => [{:say=>"Good Bye"},
                { trace: {
                  :application_id => 1,
                  :step_id => 27,
                  :store => '"Missed input for 3 times."'}}]
            }
          }
        ])
      end

      it "should be able to build itself from an incomming hash" do
        menu = Menu.new app, 'id' => 27, 'type' => 'menu', 'explanation_message' => {'name' => 'foo'}, 'timeout' => 20, 'invalid_message' => {'name' => 'foobar'} , 'end_call_message' => {'name' => 'cya'}, 'options_message' => {}
        menu.id.should eq(27)
        menu.explanation_message.should eq('foo')
        menu.timeout.should eq(20)
        menu.invalid_message.should eq('foobar')
        menu.end_call_message.should eq('cya')
      end

      it "should handle a menu input stream"do
        (Menu.can_handle? 'id' => 27, 'type' => 'menu').should be_true
        (Menu.can_handle? 'id' => 27, 'type' => 'answer').should be_false
      end

      it "should build with a collection of options" do
        menu = Menu.new app, 'id' => 27, 'type' => 'menu', 'explanation_message' => {'name' => 'foo'},
          'options' => [
            {
              'description' => 'foo',
              'number' => 1,
              'next' => 10
            },
            {
              'description' => 'bar',
              'number' => 2,
              'next' => 14
            }
          ],
          'options_message' => {},
          'end_call_message' => {},
          'invalid_message' => {}
        menu.options.size.should eq(2)
        menu.options.first['number'].should eq(1)
        menu.options.first['description'].should eq('foo')
        menu.options.first['next'].should eq(10)
        menu.options.last['number'].should eq(2)
        menu.options.last['description'].should eq('bar')
        menu.options.first['next'].should eq(10)
      end

      it "should resolve it's next links from a given list of commands" do
        menu = Menu.new app, 'id' => 27, 'type' => 'menu',
          'explanation_message' => {"name" => 'foo'},
          'options' =>[
            {
              'description' => 'foo',
              'number' => 1,
              'next' => 10
            },
            {
              'description' =>'bar',
              'number' => 2,
              'next' => 14
            }
          ],
          'options_message' => {},
          'end_call_message' => {},
          'invalid_message' => {}
        menu_2 = Menu.new app, 'id' => 10,
          'type' => 'menu',
          'explanation_message' => {"name"=>'foo'},
          'options_message' => {},
          'end_call_message' => {},
          'invalid_message' => {}
        menu_3 = Menu.new app, 'id' => 14,
          'type' => 'menu',
          'explanation_message' => {"name"=>'foo'},
          'options_message' => {},
          'end_call_message' => {},
          'invalid_message' => {}

        menu.solve_links_with [ menu_2, menu_3 ]
        menu.options[0]['next'].should eq(menu_2)
        menu.options[1]['next'].should eq(menu_3)
      end

      it "should respond if it's a root or not" do
        menu_1 = Menu.new app, 'id' => 10,
          'root' => true,
          'type' => 'menu',
          'explanation_message' => {"name"=>'foo'},
          'options_message' => {},
          'end_call_message' => {},
          'invalid_message' => {}
        menu_2 = Menu.new app, 'id' => 14,
          'type' => 'menu',
          'explanation_message' => {"name"=>'foo'},
          'options_message' => {},
          'end_call_message' => {},
          'invalid_message' => {}
        menu_1.is_root?.should be_true
        menu_2.is_root?.should be_false
      end

      def id
        1
      end
    end
  end
end