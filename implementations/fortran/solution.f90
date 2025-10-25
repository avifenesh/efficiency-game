program log_analyzer
    use iso_fortran_env, only: error_unit
    implicit none

    integer :: argc
    character(len=1024) :: filename
    integer :: ios
    integer :: errors, warnings, total
    logical :: exists
    character(len=2048) :: line

    errors = 0
    warnings = 0

    argc = command_argument_count()
    if (argc /= 1) then
        call print_usage()
        stop 1
    end if

    call get_command_argument(1, filename)
    filename = trim(filename)

    inquire(file=filename, exist=exists)
    if (.not. exists) then
        write(error_unit, '(A,1X,A)') 'Error: File not found:', trim(filename)
        stop 1
    end if

    open(unit=10, file=filename, status='old', action='read', iostat=ios)
    if (ios /= 0) then
        write(error_unit, '(A,1X,A)') 'Error: Unable to open file:', trim(filename)
        stop 1
    end if

    do
        read(10, '(A)', iostat=ios) line
        if (ios /= 0) exit

        if (index(trim(line), 'E') > 0 .and. contains_word(line, 'ERROR')) then
            errors = errors + 1
        else if (index(trim(line), 'W') > 0 .and. contains_word(line, 'WARN')) then
            warnings = warnings + 1
        end if
    end do

    close(10)

    total = errors + warnings
    write(*,'(A,I0,A,I0,A,I0,A)') '{"errors": ', errors, ', "warnings": ', warnings, ', "total": ', total, '}'

contains
    logical function contains_word(line, word) result(found)
        character(len=*), intent(in) :: line
        character(len=*), intent(in) :: word
        integer :: len_line, len_word
        integer :: search_start, raw_pos, actual_pos
        logical :: start_ok, end_ok

        len_line = len_trim(line)
        len_word = len_trim(word)
        found = .false.

        if (len_line == 0 .or. len_word == 0) return

        search_start = 1
        do while (search_start <= len_line)
            raw_pos = index(line(search_start:len_line), word)
            if (raw_pos == 0) exit
            actual_pos = search_start + raw_pos - 1

            start_ok = .true.
            if (actual_pos > 1) then
                start_ok = .not. is_alnum(line(actual_pos - 1:actual_pos - 1))
            end if

            end_ok = .true.
            if (actual_pos + len_word <= len_line) then
                end_ok = .not. is_alnum(line(actual_pos + len_word:actual_pos + len_word))
            end if

            if (start_ok .and. end_ok) then
                found = .true.
                exit
            end if

            search_start = actual_pos + 1
        end do
    end function contains_word

    logical function is_alnum(ch)
        character(len=*), intent(in) :: ch
        integer :: code

        if (len_trim(ch) == 0) then
            is_alnum = .false.
            return
        end if

        code = iachar(ch(1:1))
        is_alnum = (code >= iachar('0') .and. code <= iachar('9')) .or. &
                   (code >= iachar('A') .and. code <= iachar('Z')) .or. &
                   (code >= iachar('a') .and. code <= iachar('z'))
    end function is_alnum

    subroutine print_usage()
        write(error_unit, '(A)') 'Usage: solution <logfile>'
    end subroutine print_usage

end program log_analyzer
