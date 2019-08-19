#!/bin/bash

#JEINING
function_lib3 () {
    clear >$(tty)
    options=("Update the details" "Add copies of book" "Quit to previous")
    echo "You selected: $1, what would you like to do?"
    select opt in "${options[@]}"
    do
        case $opt in
            "Update the details")
                clear > $(tty)
                echo "You have chosen to update the Branch with:"
                oldIFS=$IFS
                IFS=$'\n'
								## query to get branch name
                dbqueryNAME=($(mysql --login-path=local $NAME -NBrs -e "SELECT branchName FROM tbl_library_branch WHERE branchName LIKE '${1:0:5}%';"))
                ## query to get branch id
								dbqueryID=($(mysql --login-path=local $NAME -NBrs -e "SELECT branchId FROM tbl_library_branch WHERE branchName LIKE '${1:0:5}%';"))
                ## query to get branch address
								dbqueryADDRESS=($(mysql --login-path=local $NAME -NBrs -e "SELECT branchAddress FROM tbl_library_branch WHERE branchName LIKE '${1:0:5}%';"))
                IFS=$oldIFS
                echo "Branch ID: $dbqueryID"
                echo "Branch Name: ${dbqueryNAME[*]}"
                echo ""
                echo "Please enter new branch name, Leave blank if no change:"

								## take new branch name from input
                read -r bname
                if [ -z  "$bname" ]; then
                    bname=$dbqueryNAME
                fi
                echo ""
                echo "Please enter new branch address, Leave blank if no change:"

								## take new branch address from input
                read -r baddress
                if [ -z  "$baddress" ]; then
                    baddress=$dbqueryADDRESS
                fi
                clear >$(tty)
                echo "Are you sure you would like to update branchID:${b}$dbqueryID${n} with Branch Name:${b}$bname${n} and Address:${b}$baddress${n}?"
                select yn in "Yes" "No"; do
                    case $yn in
                        Yes )
												## function test by testing effect row
                                error=($(mysql --login-path=local $NAME -NBrs -e "UPDATE tbl_library_branch SET branchName = '$bname', branchAddress = '$baddress' WHERE branchId = '$dbqueryID'; SELECT ROW_COUNT();"))
                                local success=$(function_test "$error")
                                echo "$success"
                                read pause
                                function_lib3 "$bname  $baddress"
                                 ;;
                        No ) function_lib3 "$1";;
                    esac
                done
                ;;

                "Add copies of book")
                    clear > $(tty)
                    echo "You have chosen to add book copies to Branch with:"
                    oldIFS=$IFS
                    IFS=$'\n'
										## query to get branch name
                    dbqueryNAME=($(mysql --login-path=local $NAME -NBrs -e "SELECT branchName FROM tbl_library_branch WHERE branchName LIKE '${1:0:5}%';"))
	                 	## query to get branch id
										dbqueryID=($(mysql --login-path=local $NAME -NBrs -e "SELECT branchId FROM tbl_library_branch WHERE branchName LIKE '${1:0:5}%';"))
                    ## query to get branch address
										dbqueryADDRESS=($(mysql --login-path=local $NAME -NBrs -e "SELECT branchAddress FROM tbl_library_branch WHERE branchName LIKE '${1:0:5}%';"))
                    ## query to get book title
										dbqueryGetCopy=($(mysql --login-path=local $NAME -NBrs -e "SELECT title FROM tbl_book JOIN tbl_book_copies on tbl_book.bookId=tbl_book_copies.bookId where branchID='$dbqueryID';"))
                    dbqueryGetCopy=( "${dbqueryGetCopy[@]}" "Quit to previous" )
                    IFS=$oldIFS
                    echo "Branch ID: $dbqueryID"
                    echo "Branch Name: ${dbqueryNAME[*]}"
                    echo ""
                    echo "Pick the Book you want to add copies to your branch:"
                    select answer in "${dbqueryGetCopy[@]}"; do
                    for item in "${dbqueryGetCopy[@]}"; do
                                    if [[ $item == $answer ]]; then

																				## query to get book id
                                        dbqueryBookID=($(mysql --login-path=local $NAME -NBrs -e "SELECT bookId FROM tbl_book WHERE title = '$answer';"))
                                        ## query to get existing book copy
																				dbqueryUpdateCopy=($(mysql --login-path=local $NAME -NBrs -e "SELECT noOfCopies from tbl_book_copies where branchID='$dbqueryID' and bookId='$dbqueryBookID';"))
                                        echo 'Existing number of copies: '
                                        echo "$dbqueryUpdateCopy"
                                        read -p 'Enter the new copy: ' newCopy

																				## function test for integer inut
                                        while ! [[ "$newCopy" =~ ^[0-9]+$ ]]; do
                                        read -p "Please enter an integer: " newCopy
                                        done

                                        clear >$(tty)
                                        echo "Are you sure you would like to update with new copy: ${b}$newCopy${n}?"
                                        select yn in "Yes" "No"; do
                                                case $yn in
                                                        Yes )
                                                        error=($(mysql --login-path=local $NAME -NBrs -e "UPDATE tbl_book_copies SET noOfCopies = '$newCopy' WHERE bookId = '$dbqueryBookID' AND branchId = '$dbqueryID'; SELECT ROW_COUNT();"))
                                                        local success=$(function_test "$error")
                                                        echo "$success"
                                                        read pause
                                                        function_lib3 "$dbqueryNAME"  "$dbqueryADDRESS"
                                                         ;;
                                                        No ) function_lib3 "$1";;
                                                esac
                                        done
                                    fi
                                    done
                    done
                    ;;
            "Quit to previous")
                function_lib2
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
}
function_lib2 () {
        clear >$(tty)
        oldIFS=$IFS
        IFS=$'\n'

				## query to get branch name and branch address
        dbquery=($(mysql --login-path=local $NAME -NBrs -e "SELECT branchName, branchAddress FROM tbl_library_branch;"))
        dbquery=( "${dbquery[@]}" "Quit to previous" )
        IFS=$oldIFS
        echo "Select Branch"
    		COLUMNS=0
        select answer in "${dbquery[@]}"; do
        for item in "${dbquery[@]}"; do
                if [[ $item == $answer ]]; then
                        break 2
                fi
                done
        done
                if [[ $answer == "Quit to previous" ]]; then
								## if user choose to quit, go back
                function_librarian
        else
					      ## ow call lib3 function
                function_lib3 "$answer"
        fi
}

#Elias
function_borrower_return () {
##prompts to enter the ID of the book you want to return
    clear >$(tty)
    IFS=$oldIFS
    echo "Enter a book ID # to return a book, or type 'exit' to return to the main menu."
   read -r bookIdentification
   if [[ "$bookIdentification" == "exit" ]]; then
       function_main
   else
       dbquery=($(mysql --login-path=local $NAME -N -B -r -e "SELECT dueDate FROM tbl_book_loans WHERE ('$bookIdentification' = bookId AND '$2' = branchID AND '$1' = CardNo AND returnDate IS NULL);"))
       ##check if the answer is null
       if [[ -z "$dbquery" ]]; then
				 	##if it is there is no record missing a return date, then the user can't have that book checked out
           echo "You have no checked out books with that book ID #. Press enter to continue."
           read -r pause
           function_borrower_return "$1" "$2"
       fi
			 ##if the record IS missing a return date it must be the checked out book, so the program fills it in with NOW()
       dbquery=($(mysql --login-path=local $NAME -N -B -r -e "CALL returnCopy('$bookIdentification', '$2', '$1');"))
       echo "Book succesfully returned. Press enter to continue."
			 read -r pause
   fi
   function_borrower_return "$1" "$2"
}
function_borrower_checkout () {
##prompts to enter the ID of book to check out
   clear >$(tty)
    IFS=$oldIFS
    echo "Enter a book ID # to check out, or type 'exit' to return to the main menu."
   read -r bookIdentification
   if [[ "$bookIdentification" == "exit" ]]; then
       function_main
   else
		 dbquery=($(mysql --login-path=local $NAME -N -B -r -e "SELECT dueDate FROM tbl_book_loans WHERE ('$bookIdentification' = bookId AND '$2' = branchID AND '$1' = CardNo AND returnDate IS NULL);"))
		 ##check if the user already has the book checked out by looking for the record
		 if [[ -z "$dbquery" ]]; then
				 ##do nothing
				 echo ""
		 else
				 echo "You have already checked that book out. You cannot do so again until you return it. Press enter to continue."
				 read -r pause
				 function_borrower_return "$1" "$2"
		 fi
       dbquery=($(mysql --login-path=local $NAME -N -B -r -e "SELECT NoOfCopies FROM tbl_book_copies WHERE ('$bookIdentification' = bookId AND '$2' = branchID);"))
       ##check if the answer is 0 or null
       if [[ "$dbquery" == 0 ]]; then
           echo "There are no books with that Book ID #. Press enter to continue."
           read -r pause
           function_borrower_checkout "$1" "$2"
       fi
       if [[ -z "$dbquery" ]]; then
           echo "Invalid Book ID #"
           read -r pause
           function_borrower_checkout "$1" "$2"
       fi
       dbquery=($(mysql --login-path=local $NAME -N -B -r -e "CALL removeCopy('$bookIdentification', '$2', '$1');"))
       echo "Book succesfully checked out. It is due in two weeks. Press enter to continue."
			 read -r pause
   fi
   function_borrower_checkout "$1" "$2"
}

#JAMES
FUNCTION_BOOK_ADD(){
    clear >$(tty)
        echo "Adding a New book and its author..."
        read -p 'Book ID: ' bid
        while ! [[ "$bid" =~ ^[0-9]+$ ]]; do
               read -p "book ID needs to be integer: " bid
                   done
        read -p 'Title: ' tle
        read -p 'Publisher ID: ' pid
        while ! [[ "$pid" =~ ^[0-9]+$ ]]; do
               read -p "Please enter integer for pubID: " pid
                   done
        read -p 'Author ID' aid
        while ! [[ "$aid" =~ ^[0-9]+$ ]]; do
               read -p "Please enter integer for authorID: " aid
               done
        read -p 'Author Name' aname
        echo ""
        clear >$(tty)
        echo "Are you sure you would like to add a new book with:"
        echo "Book ID: ${b}$bid${n}  Title: ${b}$tle${n}  publisher ID: ${b}$pid${n}?"
        echo "Author ID:  ${b}$aid${n} Author Name:${b}$aname${n}"
        options=("Yes" "No" "Quit to previous")
        select opt in "${options[@]}"
       do
               case $opt in
                    "Yes")
                        ptest=($(mysql --login-path=local $NAME -NBrs -e "SELECT EXISTS(SELECT * FROM tbl_publisher WHERE publisherid = $pid);"))
                        btest=($(mysql --login-path=local $NAME -NBrs -e "SELECT EXISTS(SELECT * FROM tbl_book WHERE bookid = $bid );"))
                        atest=($(mysql --login-path=local $NAME -NBrs -e "SELECT EXISTS(SELECT * FROM tbl_author WHERE authorid = $aid );"))
                        function_publish_test "$ptest" "$btest" "$atest" "$bid" "$tle" "$pid" "$aid" "$aname" ;;
                    "No")FUNCTION_BOOK_ADD ;;
                    "Quit to previous")function_admin_book ;;
                    *) echo "invalid option $REPLY";;
                esac
        done
}
FUNCTION_BOOK_DELETE(){
    clear >$(tty)
        echo "Delete a book and author."
        read -p 'Enter the ID or title for the book: ' Aanswer
        read -p 'the ID or name for the author: ' Banswer
        echo ""
        dba=($(mysql --login-path=local $NAME -NBrs -e "SELECT * FROM tbl_book WHERE bookid LIKE '${Aanswer}%' OR title LIKE '${Aanswer}%';"))
        dbb=($(mysql --login-path=local $NAME -NBrs -e "SELECT * FROM tbl_author WHERE authorid LIKE '${Banswer}%' OR authorname LIKE '${Banswer}%';"))
        if [ -z "$dba" ] || [ -z "$dbb" ]; then
        echo "Could not find a match"
        read -r pause
        function_admin_book
        fi
        clear >$(tty)
        echo "Are you sure you would like to delete this book with:"
        echo "Book: ${b}${dba[@]}${n}"
        echo "Author: ${b}${dbb[@]}${n}"
        options=("Yes" "No" "Quit to previous")
        select opt in "${options[@]}"
       	do
               case $opt in
                    "Yes")
                    error=($(mysql --login-path=local $NAME -NBrs -e "DELETE FROM tbl_book WHERE bookid = ${dba[0]}; DELETE FROM tbl_author WHERE authorid = ${dbb[0]};SELECT ROW_COUNT();"))
                    local success=$(function_test "$error")
                    echo "$success"
										read  -r pause
										function_administrator
                        ;;
                    "No")
                        FUNCTION_BOOK_DELETE
                        ;;
                    "Quit to previous")
                        function_admin_book
                        ;;
                esac
        done
}
FUNCTION_BOOK_UPDATE(){
    clear >$(tty)
        echo "    Update a book and author."
        read -p 'Enter the ID or title for the book: ' Aanswer
        read -p 'the ID or name for the author: ' Banswer
        echo ""
        dba=($(mysql --login-path=local $NAME -NBrs -e "SELECT * FROM tbl_book WHERE bookid LIKE '${Aanswer}%' OR title LIKE '${Aanswer}%';"))
        dbb=($(mysql --login-path=local $NAME -NBrs -e "SELECT * FROM tbl_author WHERE authorid LIKE '${Banswer}%' OR authorname LIKE '${Banswer}%';"))
        if [ -z "$dba" ] || [ -z "$dbb" ]; then
        echo "Could not find a match"
        read -r pause
        function_admin_book
        fi
        clear >$(tty)
        echo "Are you sure you would like to update this book with:"
        echo "Book: ${b}${dba[@]}${n}"
        echo "Author: ${b}${dbb[@]}${n}"
        options=("Yes" "No" "Quit to previous")
        select opt in "${options[@]}"
       do
           case $opt in
                    "Yes")
                        echo "Leave blank if no update"
                        dbNAME=($(mysql --login-path=local $NAME -NBrs -e "SELECT title FROM tbl_book WHERE bookid = ${dba[0]};"))
                        read -p 'Book name: ' a
                        if [ -z  "$a" ]; then
                            a=$dbNAME
                        fi
                        dbpublisherID=($(mysql --login-path=local $NAME -NBrs -e "SELECT pubID FROM tbl_book WHERE bookid = ${dba[0]};"))
                        read -p 'book publisher ID: ' ba
                        if [ -z  "$ba" ]; then
                            ba=$dbpublisherID
                        fi
                        dbID=($(mysql --login-path=local $NAME -NBrs -e "SELECT bookid FROM tbl_book WHERE bookid = ${dba[0]};"))
                        read -p 'book ID: ' c
                        if [ -z  "$c" ]; then
                            c=$dbID
                        fi
                        dbaname=($(mysql --login-path=local $NAME -NBrs -e "SELECT authorName FROM tbl_author WHERE authorID = ${dbb[0]};"))
                        read -p 'Author name: ' d
                        if [ -z  "$d" ]; then
                            e=$dbaname
                        fi
                        dbaID=($(mysql --login-path=local $NAME -NBrs -e "SELECT authorID FROM tbl_author WHERE authorID = ${dbb[0]};"))
                        read -p 'Author ID: ' e
                        if [ -z  "$e" ]; then
                            e=$dbaID
                        fi
                        echo ""
                        error=($(mysql --login-path=local $NAME -NBrs -e "UPDATE tbl_book SET title = '$a', pubId = '$ba', bookid = '$c' WHERE bookid = ${dba[0]}; SELECT ROW_COUNT();"))
                        local success=$(function_test "$error")
                        echo "$success"
												error=($(mysql --login-path=local $NAME -NBrs -e "update tbl_author set Authorname = '$d', authorID='$e' where authorid=${dbb[0]}; SELECT ROW_COUNT();"))
												local success=$(function_test "$error")
                        echo "$success"
                        read -r pause
                        function_admin_book
                        ;;
                    "No")
                        FUNCTION_BOOK_UPDATE
                        ;;
                    "Quit to previous")
                        function_admin_book
                        ;;
                esac
        done
}
function_publish_test(){
    if    [ $1 == 0 ]; then
        echo "The publisher ID is not in the database, please add the new publisher and then come back re-enter the information"
        FUNCTION_publisher_ADD
    elif [ $2 == 0 ]; then
        echo "do not find a match book in the database, do you want to add this book?"
        options1=("Yes" "No" "Quit to previous")
        select opt1 in "${options1[@]}"
           do
               case $opt1 in
                    "Yes")
                        result1=($(mysql --login-path=local $NAME -NBrs -e "INSERT INTO tbl_book (bookId,title,pubid) values ('$4','$5','$6') ;SELECT ROW_COUNT();"))

                        if [ "$result1" -ge "1" ]; then
                        echo "book is added"
                        read pause
                        let x=1
                        function_publish_test "$1" "$x" "$3" "$4" "$5" "$6" "$7" "$8"
                        fi
                        ;;
                    "No")FUNCTION_BOOK_ADD ;;
                    "Quit to previous")function_admin_book ;;
                    *) echo "invalid option $REPLY";;
                esac
            done
    elif [ $3 == 0 ]; then
        echo "do not find a match author in the database, do you want to add this author?"
        options2=("Yes" "No" "Quit to previous")
        select opt2 in "${options2[@]}"
           do
               case $opt2 in
                    "Yes")
                        result2=($(mysql --login-path=local $NAME -NBrs -e "INSERT INTO tbl_author (authorId,authorName) values ('$7','$8') ;SELECT ROW_COUNT();"))
                        if [ "$result2" -ge 1 ]; then
                        echo "author is added"
                        read pause
                        let y=1
                        function_publish_test "$1" "$2" "$y" "$4" "$5" "$6" "$7" "$8"
                        fi
                        ;;
                    "No")FUNCTION_BOOK_ADD ;;
                    "Quit to previous")function_admin_book ;;
                    *) echo "invalid option $REPLY";;
                esac
            done
    else
        result4=($(mysql --login-path=local $NAME -NBrs -e "select exists( select 1 from tbl_book_authors where bookId ='$4' and authorID='$7') ;"))
        if [ result4 == 1 ]; then
            echo "The author and book you enter is inside the book author table already"
            FUNCTION_BOOK_ADD
        else
            result3=($(mysql --login-path=local $NAME -NBrs -e "INSERT INTO tbl_book_authors (bookId,authorid) values ('$4','$7');SELECT ROW_COUNT();"))
            local success=$(function_test $result3)
            echo "$success"
            read pause
            function_admin_book
        fi
    fi
}
FUNCTION_publisher_ADD(){
    clear >$(tty)
        echo "Adding a New publisher..."
        read -p 'publisher ID: ' pid
        read -p 'publisher name: ' pname
        read -p 'Publisher address: ' paddress
        read -p 'Publisher phone: ' phone
        echo "You are trying to add publisherid:$pid publisherName:$pname publisher address:$paddress publisher phone:$phone into the database correct?"
        options=("Yes" "No" "Quit to previous")
        select opt in "${options[@]}"
       do
               case $opt in
                    "Yes")
                        ptest=($(mysql --login-path=local $NAME -NBrs -e "SELECT EXISTS(SELECT * FROM tbl_publisher WHERE publisherid = $pid);"))
                        if [ $ptest == 1 ]; then
                        echo "There is an existing publisher ID, please re-enter the information"
                        FUNCTION_publisher_ADD
                        else
                        result=($(mysql --login-path=local $NAME -NBrs -e "INSERT INTO tbl_publisher (publisherId,publishername,publisheraddress,publisherphone) values ('$pid','$pname','$paddress','$phone'); SELECT ROW_COUNT();"))
                        local success=$(function_test $result)
                        echo "$success"
                        read pause
                        function_administrator
                        fi
                        ;;
                    "No")
                        FUNCTION_publisher_ADD
                        ;;
                    "Quit to previous")
                        function_admin_publisher
                        ;;
                esac
        done
}
FUNCTION_publisher_DELETE(){
    clear >$(tty)
        echo "Delete a publisher."
        read -p 'Enter the ID, name ,phone or address for the publisher: ' answer
        echo ""
        db=($(mysql --login-path=local $NAME -NBrs -e "SELECT * FROM tbl_publisher WHERE publisherid = '${answer}%' OR publishername LIKE '${answer}%' or publisheraddress like '${answer}%' or publisherphone like '${answer}%' LIMIT 1;"))
        if [ -z "$db" ] ; then
        echo "Could not find a match"
        read -r pause
        function_admin_publisher
        fi
        clear >$(tty)
        echo "Are you sure you would like to delete publisher with:"
        echo "publisher: ${b}${db[@]}${n}"
        options=("Yes" "No" "Quit to previous")
        select opt in "${options[@]}"
        do
               case $opt in
                    "Yes")
                        error=($(mysql --login-path=local $NAME -NBrs -e "DELETE FROM tbl_publisher WHERE publisherid = ${db[0]}; SELECT ROW_COUNT();"))
                        local success=$(function_test1 "$error")
                        echo "$success"
												read pause
												function_administrator
                        ;;
                    "No")
                        FUNCTION_publisher_DELETE
                        ;;
                    "Quit to previous")
                        function_admin_publisher
                        ;;
                esac
        done
}
FUNCTION_publisher_UPDATE(){
    clear >$(tty)
        echo "    Update publisher."
        read -p 'Enter the ID, name , address or phone number for the publisher: ' answer
        echo ""
        db=($(mysql --login-path=local $NAME -NBrs -e "SELECT * FROM tbl_publisher WHERE publisherid = '${answer}%' OR publishername LIKE '${answer}%' or publisheraddress like '${answer}%' or publisherphone like '${answer}%' LIMIT 1;"))
        if [ -z "$db" ] ; then
        echo "Could not find a match"
        read -r pause
        function_admin_publisher
        fi
        clear >$(tty)
        echo "Are you sure you would like to update publisher with:"
        echo "publisher: ${b}${db[@]}${n}"
        options=("Yes" "No" "Quit to previous")
        select opt in "${options[@]}"
       do
               case $opt in
                    "Yes")
                        echo "Leave blank if no update"
                        dbNAME=($(mysql --login-path=local $NAME -NBrs -e "SELECT publishername FROM tbl_publisher WHERE publisherid = ${db[0]};"))
                        read -p 'publisher name: ' a
                        if [ -z  "$a" ]; then
                            a=$dbNAME
                        fi
                        dbaddress=($(mysql --login-path=local $NAME -NBrs -e "SELECT publisheraddress FROM tbl_publisher WHERE publisherid = ${db[0]};"))
                        read -p 'Publisher address: ' ba
                        if [ -z  "$ba" ]; then
                            ba=$dbaddress
                        fi
                        dbphone=($(mysql --login-path=local $NAME -NBrs -e "SELECT publisherphone FROM tbl_publisher WHERE publisherid = ${db[0]};"))
                        read -p 'publisher phone: ' c
                        if [ -z  "$c" ]; then
                            c=$dbphone
                        fi
                        dbID=($(mysql --login-path=local $NAME -NBrs -e "SELECT publisherID FROM tbl_publisher WHERE publisherID = ${db[0]};"))
                        read -p 'publisher ID: ' d
                        if [ -z  "$d" ]; then
                            d=$dbID
                        fi
                        echo ""
                        error=($(mysql --login-path=local $NAME -NBrs -e "UPDATE tbl_publisher SET publishername = '$a', publisheraddress = '$ba', publisherphone = '$c', publisherID= '$d' WHERE publisherid = ${db[0]}; SELECT ROW_COUNT();"))
                        local success=$(function_test "$error")
                        echo "$success"
                        read pause
                        function_admin_publisher
                        ;;

                    "No")
                        FUNCTION_publisher_UPDATE
                        ;;
                    "Quit to previous")
                        function_admin_publisher
                        ;;
                esac
        done
}

#RANDY
function_bor2 () {
    clear >$(tty)
       options=("Check out a book" "Return a book" "Quit to previous")
       echo "Welcome Borrower, Where to next?"
       select opt in "${options[@]}"
       do
               case $opt in
                       "Check out a book")
                               function_borrower_checkout "$1" "$2"
                               ;;
                       "Return a book")
                               function_borrower_return "$1" "$2"
                               ;;
            "Quit to previous")
                function_main
                ;;
                       *) echo "invalid option $REPLY";;
                  esac
       done
       function_bor2 "$1" "$2"
}
function_admin_publisher () {
    clear >$(tty)
       options=("ADD" "UPDATE" "DELETE" "Quit to previous")
       echo "Specify the operation you want to do?"
       select opt in "${options[@]}"
       do
               case $opt in
                       "ADD")
                               FUNCTION_publisher_ADD
                               ;;
                       "UPDATE")
                               FUNCTION_publisher_UPDATE
                               ;;
                       "DELETE")
                               FUNCTION_publisher_DELETE
                               ;;
                       "Quit to previous")
                                function_administrator
                               ;;
                       *) echo "invalid option $REPLY";;
               esac
       done
}
function_admin_book () {
    clear >$(tty)
       options=("ADD" "UPDATE" "DELETE" "Quit to previous")
       echo "Specify the operation you want to do for a book?"
       select opt in "${options[@]}"
       do
               case $opt in
                       "ADD")
                               FUNCTION_BOOK_ADD
                               ;;
                       "UPDATE")
                               FUNCTION_BOOK_UPDATE
                               ;;
                       "DELETE")
                               FUNCTION_BOOK_DELETE
                               ;;
                       "Quit to previous")
                            function_administrator
                               ;;
                       *) echo "invalid option $REPLY";;
               esac
       done
}
function_bor1 () {
    clear >$(tty)
    oldIFS=$IFS
    IFS=$'\n'
       dbquery=($(mysql --login-path=local $NAME -N -B -r -e "SELECT branchName FROM tbl_library_branch;"))
    dbquery=( "${dbquery[@]}" "exit" )
    IFS=$oldIFS
    echo "Select Branch"
    select answer in "${dbquery[@]}"; do
    for item in "${dbquery[@]}"; do
        if [[ $item == $answer ]]; then
           brID=($(mysql --login-path=local $NAME -N -B -r -e "SELECT branchID FROM tbl_library_branch WHERE '$answer' = branchName;"))
           function_bor2 "$1" "$brID"
        fi
        done
    done
    if [[ "$answer" == "exit" ]]; then
        function_borrower
    else
        function_main
    fi
   function_bor1 "$1"
}
function_librarian () {
	clear >$(tty)

        options=("Goto Branch you manage" "Quit to previous")
	echo "Welcome Librarian, Where too next?"
        select opt in "${options[@]}"
        do
                case $opt in
									## Chose one to goto branch info
                        "Goto Branch you manage")
                                function_lib2
				;;
				         ## Chose two to go back
                        "Quit to previous")
                                function_main
                                ;;
                        *) echo "invalid option $REPLY";;
                esac
        done
}
function_borrower () {
	clear >$(tty)
  	read -p 'Enter your Card #: ' a
		if ! [[ "$a" =~ ^[0-9]+$ ]]; then
			echo "Not a valid ID#... Going back to Main Menu"
			read -r pause
			function_main
		else
			error=($(mysql --login-path=local $NAME -NBrs -e "SELECT IF(EXISTS(SELECT name FROM tbl_borrower WHERE cardNo = $a),1,0);"))
			if [ $error == 1 ]; then
				function_bor1 "$a"
			else
				echo "Not a valid ID#... Going back to Main Menu"
				read -r pause
				function_main
			fi
		fi
}
function_admin_library () {
	clear >$(tty)
        options=("ADD" "UPDATE" "DELETE" "Quit to previous")
        echo "Specify the operation you want to do for a library?"
        select opt in "${options[@]}"
        do
                case $opt in
                        "ADD")
                                function_library_add
                                ;;
                        "UPDATE")
                                function_library_update
                                ;;
                        "DELETE")
                                function_library_delete
                                ;;
                        "Quit to previous")
																function_administrator
                                ;;
                        *) echo "invalid option $REPLY";;
                esac
        done
}
function_library_add () {
	clear >$(tty)
	echo "Adding a New Library..."
		read -p 'Branch name: ' x
		read -p 'Address: ' y
		dbSEARCH=($(mysql --login-path=local $NAME -NBrs -e "SELECT branchId FROM tbl_library_branch WHERE branchName = '${x}' OR branchAddress = '${y}';"))
		if [ -z  "$dbSEARCH" ]; then
			clear >$(tty)
		else
			clear >$(tty)
			echo "There is already a Library like that..."
			dbCHECK=($(mysql --login-path=local $NAME -NBrs -e "SELECT * FROM tbl_library_branch WHERE branchId = '${dbSEARCH}';"))
			echo "${dbCHECK[*]}"
		fi
		echo "Are you sure you would like to add a new library with:"
		echo "Name: ${b}$x${n}  Address: ${b}$y${n}?"
		select yn in "Yes" "No" "Quit"; do
				case $yn in
						Yes )
						error=($(mysql --login-path=local $NAME -NBrs -e "INSERT INTO tbl_library_branch (branchName, branchAddress) VALUES ('$x', '$y'); SELECT ROW_COUNT();"))
						local success=$(function_test "$error")
						echo "$success"
						read pause
						function_admin_library
						 ;;
						No ) function_library_add;;
						Quit ) function_admin_library;;
				esac
		done
}
function_library_delete () {
	clear >$(tty)
	echo "Search library ID, Name, or Address:"
	read -r answer
	db=($(mysql --login-path=local $NAME -NBrs -e "SELECT * FROM tbl_library_branch WHERE branchId LIKE '${answer}%' OR branchName LIKE '${answer}%' OR branchAddress LIKE '${answer}%' LIMIT 1;"))
	if [ -z  "$db" ]; then
		echo "Could not find a borrower."
		read -r pause
		function_admin_library
	fi
	clear >$(tty)
	echo "Is this the library you want to delete?"
	echo "Library: ${b}${db[@]}${n}"
	select yn in "Yes" "No" "Quit"; do
			case $yn in
					Yes )
					error=($(mysql --login-path=local $NAME -NBrs -e "DELETE FROM tbl_library_branch WHERE branchId = ${db[0]}; SELECT ROW_COUNT();"))
					local success=$(function_test "$error")
					echo "$success"
					read pause
					function_admin_library
					 ;;
					No ) function_library_delete;;
					Quit ) function_administrator;;
			esac
	done
}
function_library_update () {
	clear >$(tty)
	echo "Search library ID, Name, or Address:"
	read -r answer
	dbUPDATE=($(mysql --login-path=local $NAME -NBrs -e "SELECT * FROM tbl_library_branch WHERE branchId LIKE '${answer}%' OR branchName LIKE '${answer}%' OR branchAddress LIKE '${answer}%' LIMIT 1;"))
	if [ -z  "$dbUPDATE" ]; then
		echo "Could not find a library."
		read -r pause
		function_admin_library
	fi
	clear >$(tty)
	echo "Is this the library you want to update?"
	echo "library: ${b}${dbUPDATE[@]}${n}"
	select yn in "Yes" "No" "Quit"; do
			case $yn in
					Yes )
					echo "Leave blank if no update"
					dbNAME=($(mysql --login-path=local $NAME -NBrs -e "SELECT branchName FROM tbl_library_branch WHERE branchId = ${dbUPDATE[0]};"))
					read -p 'Name: ' a
					if [ -z  "$a" ]; then
						a=$dbNAME
					fi
						dbADDRESS=($(mysql --login-path=local $NAME -NBrs -e "SELECT branchAddress FROM tbl_library_branch WHERE branchId = ${dbUPDATE[0]};"))
						read -p 'Address: ' ba
					if [ -z  "$ba" ]; then
						b=$dbADDRESS
					fi
					echo ""

					error=($(mysql --login-path=local $NAME -NBrs -e "UPDATE tbl_library_branch SET name = '$a', address = '$ba' WHERE branchId = ${dbUPDATE[0]}; SELECT ROW_COUNT();"))
					local success=$(function_test "$error")
					echo "$success"
					read pause
					function_admin_library
					 ;;
					No ) function_library_update;;
					Quit ) function_administrator;;
			esac
	done
}
function_admin_borrower () {
	clear >$(tty)
        options=("ADD" "UPDATE" "DELETE" "Quit to previous")
        echo "Specify the operation you want to do for a borrower?"
        select opt in "${options[@]}"
        do
                case $opt in
                        "ADD")
                                function_borrower_add
                                ;;
                        "UPDATE")
                                function_borrower_update
                                ;;
                        "DELETE")
                                function_borrower_delete
                                ;;
                        "Quit to previous")
																function_administrator
                                ;;
                        *) echo "invalid option $REPLY";;
                esac
        done
}
function_borrower_add () {
	clear >$(tty)
	echo "Adding a New Borrower..."
		read -p 'Full name: ' x
		read -p 'Address: ' y
		read -p 'Phone#: "XXXXXXXXXX": ' z
		dbSEARCH=($(mysql --login-path=local $NAME -NBrs -e "SELECT cardNo FROM tbl_borrower WHERE name = '${x}' OR address = '${y}' OR phone = '${z}';"))
		if [ -z  "$dbSEARCH" ]; then
			clear >$(tty)
		else
			clear >$(tty)
			echo "There is already a Borrower like that..."
			dbCHECK=($(mysql --login-path=local $NAME -NBrs -e "SELECT * FROM tbl_borrower WHERE cardNo = '${dbSEARCH}';"))
			echo "${dbCHECK[*]}"
		fi
		echo "Are you sure you would like to add a new borrower with:"
		echo "Name: ${b}$x${n}  Address: ${b}$y${n}  Phone#: ${b}$z${n}?"
		select yn in "Yes" "No" "Quit"; do
				case $yn in
						Yes )
						error=($(mysql --login-path=local $NAME -NBrs -e "INSERT INTO tbl_borrower (name, address, phone, balance) VALUES ('$x', '$y', '$z', '0'); SELECT ROW_COUNT();"))
						local success=$(function_test "$error")
						echo "$success"
						read pause
						function_admin_borrower
						 ;;
						No ) function_borrower_add;;
						Quit ) function_admin_borrower;;
				esac
		done
}
function_borrower_delete () {
	clear >$(tty)
	echo "Search borrower ID, Name, Address, or Phone# to Delete:"
	read -r answer
	db=($(mysql --login-path=local $NAME -NBrs -e "SELECT * FROM tbl_borrower WHERE cardNo LIKE '${answer}%' OR name LIKE '${answer}%' OR address LIKE '${answer}%' OR phone LIKE '${answer}%' LIMIT 1;"))
	if [ -z  "$db" ]; then
		echo "Could not find a borrower."
		read -r pause
		function_admin_borrower
	fi
	clear >$(tty)
	echo "Is this the borrower you want to delete?"
	echo "Borrower: ${b}${db[@]}${n}"
	select yn in "Yes" "No" "Quit"; do
			case $yn in
					Yes )
					error=($(mysql --login-path=local $NAME -NBrs -e "DELETE FROM tbl_borrower WHERE cardNo = ${db[0]}; SELECT ROW_COUNT();"))
					local success=$(function_test "$error")
					echo "$success"
					read pause
					function_admin_borrower
					 ;;
					No ) function_borrower_delete;;
					Quit ) function_administrator;;
			esac
	done
}
function_borrower_update () {
	clear >$(tty)
	echo "Search borrower ID, Name, Address, or Phone# to Update:"
	read -r answer
	dbUPDATE=($(mysql --login-path=local $NAME -NBrs -e "SELECT * FROM tbl_borrower WHERE cardNo LIKE '${answer}%' OR name LIKE '${answer}%' OR address LIKE '${answer}%' OR phone LIKE '${answer}%' LIMIT 1;"))
# TEST IF QUERY CAME BACK EMPTY
	if [ -z  "$dbUPDATE" ]; then
		echo "Could not find a borrower."
		read -r pause
		function_admin_borrower
	fi
	clear >$(tty)
	echo "Is this the borrower you want to update?"
	echo "Borrower: ${b}${dbUPDATE[@]}${n}"
	select yn in "Yes" "No" "Quit"; do
			case $yn in
					Yes )
					echo "Leave blank if no update"
					dbNAME=($(mysql --login-path=local $NAME -NBrs -e "SELECT name FROM tbl_borrower WHERE cardNo = ${dbUPDATE[0]};"))
					read -p 'Name: ' a
					#IF EMPTY LEAVE VALUE AS CURRENT
					if [ -z  "$a" ]; then
						a=$dbNAME
					fi
						dbADDRESS=($(mysql --login-path=local $NAME -NBrs -e "SELECT address FROM tbl_borrower WHERE cardNo = ${dbUPDATE[0]};"))
						read -p 'Address: ' ba
					if [ -z  "$ba" ]; then
						b=$dbADDRESS
					fi
						dbPHONE=($(mysql --login-path=local $NAME -NBrs -e "SELECT phone FROM tbl_borrower WHERE cardNo = ${dbUPDATE[0]};"))
						read -p 'Phone#: ' c
					if [ -z  "$c" ]; then
						c=$dbPHONE
					fi
						dbBALANCE=($(mysql --login-path=local $NAME -NBrs -e "SELECT BALANCE FROM tbl_borrower WHERE cardNo = ${dbUPDATE[0]};"))
					read -p 'Balance: ' d
					if [ -z  "$d" ]; then
						d=$dbBALANCE
					else
						#LOOP UNTIL AN INTEGER IS ENTERED
						while ! [[ "$d" =~ ^[0-9]+$ ]]; do
							read -p "Balance: " d
							if [ -z  "$d" ]; then
								d=$dbBALANCE
								echo "Are you sure you would like to to change this borrower?"
								echo "${dbUPDATE[0]} $a $ba $c $d"
								select yn in "Yes" "No"; do
										case $yn in
												Yes )
												error=($(mysql --login-path=local $NAME -NBrs -e "UPDATE tbl_borrower SET name = '$a', address = '$ba', phone = '$c', balance = '$d' WHERE cardNo = ${dbUPDATE[0]}; SELECT ROW_COUNT();"))
												local success=$(function_test "$error")
												echo "$success"
												read pause
												function_admin_borrower
												 ;;
												No ) function_administrator;;
										esac
								done
								echo ""
							fi
						done
					fi
					echo "Are you sure you would like to to change this borrower?"
					echo "${dbUPDATE[0]} $a $ba $c $d"
					select yn in "Yes" "No"; do
							case $yn in
									Yes )
									error=($(mysql --login-path=local $NAME -NBrs -e "UPDATE tbl_borrower SET name = '$a', address = '$ba', phone = '$c', balance = '$d' WHERE cardNo = ${dbUPDATE[0]}; SELECT ROW_COUNT();"))
									local success=$(function_test "$error")
									echo "$success"
									read pause
									function_admin_borrower
									 ;;
									No ) function_administrator;;
							esac
					done
					echo ""
					 ;;
					No ) function_borrower_update;;
					Quit ) function_administrator;;
			esac
	done
}
function_update_date () {
	clear >$(tty)
	read -p 'BorrowerID: ' x
	while ! [[ "$x" =~ ^[0-9]+$ ]]; do
		echo "Not a Valid ID"
		read -p "BorrowerID: " x
		clear >$(tty)
	done
	oldIFS=$IFS
	IFS=$'\n'
	dbquery=($(mysql --login-path=local $NAME -NBrs -e "SELECT title from tbl_book tb join tbl_book_loans tbl ON tb.bookId = tbl.bookId WHERE tbl.cardNo = '$x';"))
	if [ -z  "$dbquery" ]; then
		dbNAME=($(mysql --login-path=local $NAME -NBrs -e "SELECT name from tbl_borrower WHERE cardNo = '$x';"))
		echo "$dbNAME does not have any books checked out."
		read -r pause
		function_administrator
	else
		dbquery=( "${dbquery[@]}" "Quit to previous" )
		IFS=$oldIFS
		echo "Select the Book:"
		select answer in "${dbquery[@]}"; do
		for item in "${dbquery[@]}"; do
						if [[ $item == $answer ]]; then
										break 2
						fi
						done
		done
					if [[ $answer == "Quit to previous" ]]; then
						function_administrator
					else
						echo "Are you sure you would like to Override the due date?"
						select yn in "Yes" "No"; do
								case $yn in
										Yes )
										dbbID=($(mysql --login-path=local $NAME -NBrs -e "SELECT branchId from tbl_book_loans WHERE cardNo = '$x';"))
										dbbrID=($(mysql --login-path=local $NAME -NBrs -e "SELECT bookId from tbl_book WHERE title = '$answer';"))
										error=($(mysql --login-path=local $NAME -NBrs -e "UPDATE tbl_book_loans SET dueDate = '2222-11-11 11:11:11' WHERE branchId = '$dbbrID' AND bookId = '$dbbID' AND cardNo = '$x'; SELECT ROW_COUNT();"))
										local success=$(function_test "$error")
										echo "$success"
										read pause
										function_administrator
										 ;;
										No ) function_administrator;;
								esac
						done
					fi
fi
}
function_administrator () {
	#sets formating for entire program
	COLUMNS=0
		clear >$(tty)
        options=("A/U/D Book and Author" "A/U/D Publishers" "A/U/D Library Branches" "A/U/D Borrowers" "Over-ride Due Date" "Quit to previous")
        echo "Welcome Admin, Where to next?"
        select opt in "${options[@]}"
        do
                case $opt in
                        "A/U/D Book and Author")
															function_admin_book
                                ;;
                        "A/U/D Publishers")
                                function_admin_publisher
                                ;;
                        "A/U/D Library Branches")
                                function_admin_library
                                ;;
												"A/U/D Borrowers")
													 			function_admin_borrower
																;;
												"Over-ride Due Date")
																function_update_date
																;;
                        "Quit to previous")
																function_main
                                ;;
                        *) echo "invalid option $REPLY";;
                esac
        done
}
function_main () {
	clear >$(tty)
	options=("Librarian" "Administrator" "Borrower" "Exit")
	echo "Welcome to the GCIT Library Management System. Which category of a user are you?"
	select opt in "${options[@]}"; do
		case $opt in
			"Librarian")
				function_librarian
				;;
			"Administrator")
				clear >$(tty)
				read -s -p "Password: " pass
				echo '$pass'
				if [ $pass = 'randy' ]; then
					function_administrator
				else
					echo "Invalid Password"
					read -r pause
					function_main
				fi
				;;
			"Borrower")
				function_borrower
				;;
			"Exit")
				clear >$(tty)
				exit 0
				;;
			*) echo "invalid option $REPLY";;
		 esac
	 done
}
#test if query was successful
function_test () {
	if [ "$1" -ge "1" ]; then
		echo "Query Successful..."
	elif [ $1 == 0 ]; then
		echo "No data changed..."
	elif [ $1 == -1 ]; then
		echo "ERROR..."
	fi
}
NAME='libraryDBMS'
b=$(tput bold)
n=$(tput sgr0)
#BEGIN PROGRAM!
function_main



#Stored Procedures
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_book`(IN bid int, IN ti VARCHAR(45), IN PID INT,out FLAg int)
BEGIN
  declare bol boolean;

  SELECT EXISTS(SELECT * FROM tbl_book WHERE bookId = bId) INTO bol;
  if (bol<>1) then
  INSERT INTO TBL_BOOK (bookId,title,pubId) values(bid,ti,pid) ;
  SET flag=1;
  else
  set flag=0;
  end if;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_borrower`(IN cNo int, IN bAddress VARCHAR(45), IN bname varchar(45), bphone int, out FLAg int)
BEGIN
  declare bol boolean;
  SELECT EXISTS(SELECT * FROM tbl_borrower WHERE cNo = cardNo) INTO bol;
  if (bol<>1) then
  INSERT INTO TBL_borrower (cardNoID,name,Address,phone) values(cno,bName,bAddress,bPhone) ;
  set flag=1;
  else
  set flag=0;
end if;
END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_branch`(IN BRid int, IN BrAddress VARCHAR(45), IN BRname varchar(45),out FLAg int)
BEGIN
  declare bol boolean;
  SELECT EXISTS(SELECT * FROM tbl_publisher WHERE branchId = brId) INTO bol;
  if (bol<>1) then
  INSERT INTO TBL_library_branch (branchID,branchNAME,branchAddress) values(brid,brname,braddress) ;
  set flag=1;
  else
  set flag=0;
end if;
END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_publisher`(IN pid int, IN pADDRESS VARCHAR(45), IN Pname varchar(45),out FLAg int)
BEGIN
  declare bol boolean;
  SELECT EXISTS(SELECT * FROM tbl_publisher WHERE publisherId = pId) INTO bol;
  if (bol<>1) then
  INSERT INTO TBL_publisher (publisherID,PUBLISHERNAME,publisherAddress) values(pid,pname,paddress) ;
  set flag=1;
  else
  set flag=0;
end if;
END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `CheckID`(IN ID INT(11))
BEGIN
    SELECT borrowerName WHERE cardid = ID;
	END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `CountCopies`(IN BkID INT(11), BrcID INT(11))
BEGIN
	SELECT noOfCopies
    FROM tbl_book_copies
    WHERE (BkID = bookId AND BrcID = branchID);
    END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `CountOrderByStatus`(
 IN orderStatus VARCHAR(25),
 OUT total INT)
BEGIN
 SELECT count(title)
 INTO total
 FROM tbl_book
 WHERE pubId= orderStatus;
END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_Book`(IN bid int,out flag int)
BEGIN
  declare affect_row int;
  DeLETE from tbl_book where bookid=bid;
  select row_count() into affect_row;
  if affect_row>0 then
  SET flag=1;
  else
  set flag=0;
  end if;
END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_borrower`(IN cNo int,out FLAg int)
BEGIN
  declare affect_row int;
  delete from TBL_borrower where cardNo=cNo;
  select row_count() into affect_row;
  if affect_row>0 then
  SET flag=1;
  else
  set flag=0;
  end if;
END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_branch`(IN brid int,out FLAg int)
BEGIN
  declare affect_row int;
  delete from TBL_library_branch where branchId = brId;
  select row_count() into affect_row;
  if affect_row>0 then
  SET flag=1;
  else
  set flag=0;
  end if;
END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_publisher`(IN pid int,out FLAg int)
BEGIN
  declare affect_row int;
  delete from TBL_publisher where publisherID=pid;
  select row_count() into affect_row;
  if affect_row>0 then
  SET flag=1;
  else
  set flag=0;
  end if;
END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllBranchName`()
begin
SELECT * FROM tbl_library_branch;
end ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `over_ride`(IN bid int, in brid int, in cNo int, out flag int)
begin
declare affect_row int;
UPDATE tbl_book_loan
SET
    duedate = '2222-11-11 11:11:11'
WHERE
    cardno = ncno AND bookid = bid
        AND branchid = brid;
SELECT ROW_COUNT() INTO affect_row;
  if affect_row>0 then
  SET flag=1;
  else
  set flag=0;
  end if;
end ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `removeCopy`(IN BkID INT(11), BrcID INT(11), crdNo INT(11))
BEGIN
    UPDATE tbl_book_copies
   SET noOfCopies = noOfCopies - 1
   WHERE (BkID = bookId AND BrcID = branchID);
   INSERT INTO tbl_book_loans (bookId, branchID, CardNo, dateOut, dueDate, returnDate)
   VALUES (BkID, BrcID, crdNO, NOW(), date_add(NOW(), INTERVAL 14 DAY), NULL);
   END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `returnCopy`(IN BkID INT(11), BrcID INT(11), crdNo INT(11))
BEGIN
    UPDATE tbl_book_copies
   SET noOfCopies = noOfCopies + 1
   WHERE (BkID = bookId AND BrcID = branchID);
   UPDATE tbl_book_loans
   SET returnDate = NOW()
   WHERE (BkID = bookId AND BrcID = branchID AND CardNo = crdNo AND returnDate IS NULL);
   END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_book`(IN bid int,IN NBID int,IN NTI varchar(45),IN NPID int,out flag int)
begin
  declare affect_row int;
  update tbl_book set bookid=nbid and title=nti and pubid=npid where bookid=bid;
   select row_count() into affect_row;
  if affect_row>0 then
  SET flag=1;
  else
  set flag=0;
  end if;
END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_borrower`(IN cNo int,IN NcNo int,IN nbAddress varchar(45),IN nbName varchar(45) ,out FLAg int)
BEGIN
  declare affect_row int;
  update tbl_library_branch set cardno=ncno and NAME=nbname and Address=nbAddress where cardNo = cno;
  select row_count() into affect_row;
  if affect_row>0 then
  SET flag=1;
  else
  set flag=0;
  end if;
END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_branch`(IN brid int,IN NbrPid int,IN nbraddress varchar(45),IN nbrname varchar(45) ,out FLAg int)
BEGIN
  declare affect_row int;
  update tbl_library_branch set branchID=nbrid and branchNAME=nbrname and branchAddress=nbraddress where branchId = brId;
  select row_count() into affect_row;
  if affect_row>0 then
  SET flag=1;
  else
  set flag=0;
  end if;
END ;;
DELIMITER ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_publisher`(IN pid int,IN NPid int,IN npaddress varchar(45),IN npname varchar(45) ,out FLAg int)
BEGIN
  declare affect_row int;
  update TBL_publisher set publisherID=npid and PUBLISHERNAME=npname and publisherAddress=npaddress where publisherID=pid;
  select row_count() into affect_row;
  if affect_row>0 then
  SET flag=1;
  else
  set flag=0;
  end if;
END ;;
DELIMITER ;
