$tester = (options[:tester] || OrigenTesters::J750).new
$tester.set_timeset('func', 40)
if options[:version]
  # $top is used here instead of $dut to test that Origen will provide
  # the $dut alias automatically
  $top    = options[:dut].new(options[:version])
else
  $top    = options[:dut].new
end
Origen.mode = :debug
