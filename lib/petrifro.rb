require 'rubygems'
require 'gnuplot'

# Experiment is a module where you can use to plot and benchmark pieces of code
# and plot it on a gnuplot
#
module Petrifro
  class << self

    def timer
      start_time = Time.now
      yield
      diff_time = Time.now - start_time
      puts "That run took #{diff_time} seconds"
      return diff_time
    end

    # takes range to try and the step resolution of the range and runs 
    # the benchmark_block with each of the different ranges. 
    # the init_proc only gets run once during setup.
    #
    # Experiment::benchmark((1..50), 10, 
    #            proc { |col_size| DMatrix.rand(500, col_size)},
    #            proc { |matrix, col_size| ProbSpace.new(matrix).entropy })
    def benchmark(range, resolution, init_proc, benchmark_block)
      xs, ts = [], []
      range.step(resolution) do |x_size|
        object = init_proc.call(x_size)
        xs << x_size
        ts << timer { benchmark_block.call(object, x_size) }
      end
      plot(xs, ts)
    end

    # same idea as benchmark, but does two at the same time.  So 
    # it takes an init_proc to initialize the experiment, 
    # and two different procs, standard and comparison, to run 
    # for each step in the range at the given resolution.
    #
    # Experiment::benchmark((1..50), 10, 
    #            proc { |col_size| DMatrix.rand(500, col_size)},
    #            proc { |matrix, col_size| ProbSpace.new(matrix).entropy1 },
    #            proc { |matrix, col_size| ProbSpace.new(matrix).entropy2 })
    def compare(range, resolution, init_proc, 
                standard_block, comparison_block)
      xs, s_ts, c_ts = [], [], []
      range.step(resolution) do |x_size|
        object = init_proc.call(x_size)
        xs << x_size
        s_ts << timer { standard_block.call(object, x_size) }
        c_ts << timer { comparison_block.call(object, x_size) }
        puts "#{x_size} = standard : comparison :: #{s_ts.last} : #{c_ts.last} secs"
      end
      plot(xs, s_ts, c_ts)
    end

    def plot(x, *ys)
      Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|
          ys.each do |y|
            plot.data << Gnuplot::DataSet.new([x, y]) do |ds|
              ds.with = "linespoints"
              ds.notitle
            end
          end
        end
      end
    end

  end
end

