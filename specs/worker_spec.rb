require File.expand_path('../common', __FILE__)

EM.describe 'Worker' do
  before do
    @queue = EM::PriorityQueue.new
    @worker = GetThemAll::Worker.new(:test, 0, @queue)
    
    @downloader = stub('Downloader', :storage => nil)
    
    timeout(2)
  end
  
  should 'be idle without a job' do
    @worker.should.be.idle?
    done
  end
  
  should 'call action_succeeded on success' do
    ret = EM::DefaultDeferrable.new
    ret.succeed()
    
    ret.expects(:do_action)
    @worker.expects(:action_succeeded)
    
    action = ret
    
    @queue.push(action, 0)
    done
  end
  
  should 'call action_failed on error' do
    ret = EM::DefaultDeferrable.new
    ret.fail()
    
    ret.expects(:do_action)
    @worker.expects(:action_failed)
    
    action = ret
    
    @queue.push(action, 0)
    done
  end
  
  should 'requeue action on error' do
    action = stub('Action', :level => 2)
    @worker.instance_variable_set(:@current_action, action)
    
    @queue.expects(:push).with(action, 1)
    
    @worker.send(:action_failed)
    done
  end
  
end
