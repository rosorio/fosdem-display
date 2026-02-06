require 'minitest/autorun'
require 'date'
require_relative 'schedule_logic'

class TestScheduleLogic < Minitest::Test
  def setup
    @text_schedule = [
      ["10:00", 20, "Speaker A", "Talk A"],
      ["10:25", 30, "Speaker B", "Talk B"],
      ["11:00", 15, "Speaker C", "Talk C"]
    ]
    @date = "2026-02-06"
    @tz = "CET"
  end

  # Tests for parse_schedule
  def test_parse_schedule_creates_correct_number_of_entries
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Parse schedule creates correct number of entries"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    puts "  Input: #{@text_schedule.length} talks"
    puts "  Output: #{schedule.length} schedule entries"
    puts "  ✓ PASS: Created correct number of entries"
    assert_equal 3, schedule.length
  end

  def test_parse_schedule_creates_correct_start_times
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Parse schedule creates correct start times"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    expected_start = DateTime.strptime("#{@date} 10:00 #{@tz}", "%Y-%m-%d %H:%M %Z")
    puts "  First talk input time: #{@text_schedule[0][0]}"
    puts "  Expected start: #{expected_start.strftime('%Y-%m-%d %H:%M %Z')}"
    puts "  Actual start:   #{schedule[0][0].strftime('%Y-%m-%d %H:%M %Z')}"
    puts "  ✓ PASS: Start time correctly parsed"
    assert_equal expected_start, schedule[0][0]
  end

  def test_parse_schedule_calculates_correct_end_times
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Parse schedule calculates correct end times"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    expected_end = DateTime.strptime("#{@date} 10:20 #{@tz}", "%Y-%m-%d %H:%M %Z")
    puts "  Talk starts at: #{@text_schedule[0][0]}"
    puts "  Talk duration: #{@text_schedule[0][1]} minutes"
    puts "  Expected end: #{expected_end.strftime('%H:%M')}"
    puts "  Actual end:   #{schedule[0][1].strftime('%H:%M')}"
    puts "  ✓ PASS: End time correctly calculated"
    assert_equal expected_end, schedule[0][1]
  end

  def test_parse_schedule_preserves_speaker_and_title
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Parse schedule preserves speaker and title"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    puts "  Input speaker: '#{@text_schedule[0][2]}'"
    puts "  Output speaker: '#{schedule[0][2]}'"
    puts "  Input title: '#{@text_schedule[0][3]}'"
    puts "  Output title: '#{schedule[0][3]}'"
    puts "  ✓ PASS: Speaker and title preserved"
    assert_equal "Speaker A", schedule[0][2]
    assert_equal "Talk A", schedule[0][3]
  end

  # Tests for find_current_talk
  def test_find_current_talk_before_first_talk
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Find current talk - before first talk"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    now = DateTime.strptime("#{@date} 09:00 #{@tz}", "%Y-%m-%d %H:%M %Z")
    current = ScheduleLogic.find_current_talk(schedule, now, 0)
    puts "  Current time: #{now.strftime('%H:%M')}"
    puts "  First talk starts: #{schedule[0][0].strftime('%H:%M')}"
    puts "  Current talk index: #{current}"
    puts "  ✓ PASS: Correctly pointing to first talk (index 0)"
    assert_equal 0, current
  end

  def test_find_current_talk_during_first_talk
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Find current talk - during first talk"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    now = DateTime.strptime("#{@date} 10:10 #{@tz}", "%Y-%m-%d %H:%M %Z")
    current = ScheduleLogic.find_current_talk(schedule, now, 0)
    puts "  Current time: #{now.strftime('%H:%M')}"
    puts "  First talk: #{schedule[0][0].strftime('%H:%M')} - #{schedule[0][1].strftime('%H:%M')}"
    puts "  Current talk index: #{current}"
    puts "  ✓ PASS: Still showing first talk (index 0)"
    assert_equal 0, current
  end

  def test_find_current_talk_between_talks
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Find current talk - between talks"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    now = DateTime.strptime("#{@date} 10:22 #{@tz}", "%Y-%m-%d %H:%M %Z")
    current = ScheduleLogic.find_current_talk(schedule, now, 0)
    puts "  Current time: #{now.strftime('%H:%M')}"
    puts "  First talk ended: #{schedule[0][1].strftime('%H:%M')}"
    puts "  Second talk starts: #{schedule[1][0].strftime('%H:%M')}"
    puts "  Current talk index: #{current}"
    puts "  ✓ PASS: Advanced to second talk (index 1)"
    assert_equal 1, current
  end

  def test_find_current_talk_during_second_talk
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Find current talk - during second talk"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    now = DateTime.strptime("#{@date} 10:30 #{@tz}", "%Y-%m-%d %H:%M %Z")
    current = ScheduleLogic.find_current_talk(schedule, now, 0)
    puts "  Current time: #{now.strftime('%H:%M')}"
    puts "  Second talk: #{schedule[1][0].strftime('%H:%M')} - #{schedule[1][1].strftime('%H:%M')}"
    puts "  Current talk index: #{current}"
    puts "  ✓ PASS: Showing second talk (index 1)"
    assert_equal 1, current
  end

  def test_find_current_talk_after_all_talks
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Find current talk - after all talks"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    now = DateTime.strptime("#{@date} 12:00 #{@tz}", "%Y-%m-%d %H:%M %Z")
    current = ScheduleLogic.find_current_talk(schedule, now, 0)
    puts "  Current time: #{now.strftime('%H:%M')}"
    puts "  Last talk ended: #{schedule[2][1].strftime('%H:%M')}"
    puts "  Current talk index: #{current} (past all talks)"
    puts "  Total talks: #{schedule.length}"
    puts "  ✓ PASS: Index beyond schedule length indicates all talks finished"
    assert_equal 3, current
  end

  # Tests for calculate_delay
  def test_calculate_delay_before_talk_starts
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Calculate delay - before talk starts (5 minutes)"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    now = DateTime.strptime("#{@date} 09:55 #{@tz}", "%Y-%m-%d %H:%M %Z")
    delay = ScheduleLogic.calculate_delay(schedule, 0, now)
    puts "  Current time: #{now.strftime('%H:%M')}"
    puts "  Talk starts: #{schedule[0][0].strftime('%H:%M')}"
    puts "  Delay: #{delay} seconds (#{delay / 60} minutes)"
    puts "  ✓ PASS: Correctly calculated 300 seconds (5 minutes) until start"
    assert_equal 300, delay
  end

  def test_calculate_delay_during_talk
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Calculate delay - during talk (10 minutes in)"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    now = DateTime.strptime("#{@date} 10:10 #{@tz}", "%Y-%m-%d %H:%M %Z")
    delay = ScheduleLogic.calculate_delay(schedule, 0, now)
    puts "  Current time: #{now.strftime('%H:%M')}"
    puts "  Talk started: #{schedule[0][0].strftime('%H:%M')}"
    puts "  Talk ends: #{schedule[0][1].strftime('%H:%M')}"
    puts "  Delay: #{delay} seconds (#{delay / 60} minutes remaining)"
    puts "  ✓ PASS: Correctly calculated 600 seconds (10 minutes) remaining"
    assert_equal 600, delay
  end

  def test_calculate_delay_one_second_before_talk
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Calculate delay - 1 second before talk"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    now = DateTime.strptime("#{@date} 09:59:59 #{@tz}", "%Y-%m-%d %H:%M:%S %Z")
    delay = ScheduleLogic.calculate_delay(schedule, 0, now)
    puts "  Current time: #{now.strftime('%H:%M:%S')}"
    puts "  Talk starts: #{schedule[0][0].strftime('%H:%M:%S')}"
    puts "  Delay: #{delay} second(s)"
    puts "  ✓ PASS: Correctly calculated 1 second until start"
    assert_equal 1, delay
  end

  def test_calculate_delay_one_second_remaining
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Calculate delay - 1 second remaining in talk"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    now = DateTime.strptime("#{@date} 10:19:59 #{@tz}", "%Y-%m-%d %H:%M:%S %Z")
    delay = ScheduleLogic.calculate_delay(schedule, 0, now)
    puts "  Current time: #{now.strftime('%H:%M:%S')}"
    puts "  Talk ends: #{schedule[0][1].strftime('%H:%M:%S')}"
    puts "  Delay: #{delay} second(s) remaining"
    puts "  ✓ PASS: Correctly calculated 1 second remaining"
    assert_equal 1, delay
  end

  def test_calculate_delay_returns_nil_when_past_all_talks
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Calculate delay - past all talks"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    now = DateTime.strptime("#{@date} 12:00 #{@tz}", "%Y-%m-%d %H:%M %Z")
    delay = ScheduleLogic.calculate_delay(schedule, 3, now)
    puts "  Current time: #{now.strftime('%H:%M')}"
    puts "  Talk index: 3 (beyond schedule)"
    puts "  Delay: #{delay.inspect}"
    puts "  ✓ PASS: Returns nil when past all talks"
    assert_nil delay
  end

  def test_calculate_delay_exact_start_time
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Calculate delay - exactly at start time"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)
    now = DateTime.strptime("#{@date} 10:00 #{@tz}", "%Y-%m-%d %H:%M %Z")
    delay = ScheduleLogic.calculate_delay(schedule, 0, now)
    puts "  Current time: #{now.strftime('%H:%M')}"
    puts "  Talk starts: #{schedule[0][0].strftime('%H:%M')}"
    puts "  Delay: #{delay} seconds"
    puts "  Note: At exact start time, treated as 'before' (countdown shows 0)"
    puts "  ✓ PASS: Returns 0 at exact start time"
    assert_equal 0, delay
  end

  # Integration test
  def test_full_workflow
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "TEST: Full workflow integration test"
    schedule = ScheduleLogic.parse_schedule(@text_schedule, @date, @tz)

    puts "\n  Scenario 1: Before any talks (09:00)"
    now = DateTime.strptime("#{@date} 09:00 #{@tz}", "%Y-%m-%d %H:%M %Z")
    current = ScheduleLogic.find_current_talk(schedule, now, 0)
    delay = ScheduleLogic.calculate_delay(schedule, current, now)
    puts "    Current time: #{now.strftime('%H:%M')}"
    puts "    Current talk index: #{current}"
    puts "    Delay: #{delay} seconds (#{delay / 60} minutes until start)"
    assert_equal 0, current
    assert_equal 3600, delay

    puts "\n  Scenario 2: During first talk (10:05)"
    now = DateTime.strptime("#{@date} 10:05 #{@tz}", "%Y-%m-%d %H:%M %Z")
    current = ScheduleLogic.find_current_talk(schedule, now, current)
    delay = ScheduleLogic.calculate_delay(schedule, current, now)
    puts "    Current time: #{now.strftime('%H:%M')}"
    puts "    Current talk index: #{current}"
    puts "    Delay: #{delay} seconds (#{delay / 60} minutes remaining)"
    puts "  ✓ PASS: Full workflow behaves correctly"
    assert_equal 0, current
    assert_equal 900, delay
  end
end
