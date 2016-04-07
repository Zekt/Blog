Title: C++ 函數回傳值作為 Reference 參數造成的 rvalue 問題
Date: 2015-04-08 15:30
Category: 語言
Tags: C++

某次在寫 stack 題時出現的 code，因為題目中 pop stack A 時必定會 push 一元素進 stack A，然後我很無聊的想把 pop 跟 push 一起解決因此出現下面的 code:

宣告的部份，一個 stack 由一堆 elem 構成，
用最上面的 elem 作為 top 代表一個 stack，
因為 top 會變動故 Call by reference。
因為題目有如上性質令 pop 時會回傳新的 top。

	:::C++
	void push(int n, elem* &top);
	elem* pop(elem* &top);

依據題目性質，stack A pop 時直接將新元素 push 進 stack A:

	:::C++
	push(n, pop(A));

這時就噴錯了，登登！  
`error: invalid initialization of non-const reference of type ‘elem*&’ from an rvalue of type ‘elem*’`  
因為 call by reference 時不能丟 rvalue 的 reference 當 parameter，因為這樣 rvalue 的值可能會被直接變動，所以 C++ 標準禁止這麼做，這時有兩個解決辦法：

1.分開寫，這次這個函數剛好不需要回傳值，其他狀況的話應該要將回傳值先存到暫時變數：

	:::C++
	pop(A);
	push(n, A);
	//it works!!
	
   	elem* tmp = pop(A);
	push(n, tmp);
	//pop的回傳值需要被處理的情況

2.宣告時加 const 使 reference 不能被變動:

	:::C++
	void push(elem* const &n, elem* &top);
	
	...
		
	push(pop(A), B);

又噴錯了 QAQ：  
`error: invalid initialization of non-const reference of type ‘const elem*&’ from an rvalue of type ‘elem*’`
因為這是「一個const的elem指標」的reference，但是reference依舊不是const，所以要這樣解決：

	:::C++
	void push(int n, elem* const &top);

這樣 top 才會被視為一個 const 的「elem 指標的 reference」。

為了避免模糊重點可以把問題簡化成這樣：(<del>就是上面其實可以都不用看的意思</del>)

	:::C++
	void func1(int* &a);
	int* func2();

	func1(func2());
	//error: invalid initialization of non-const reference of type ‘int*&’ from an rvalue of type ‘int*’


	void func1(const int* &a);
	int* func2();

	func1(func2());
	//error: invalid initialization of non-const reference of type ‘const int*&’ from an rvalue of type ‘int*’


	void func1(int* const &a);
	int* func2();

	func1(func2());
	//it works!!

終於成功了 QAQ，不過這些好像大部份是常識(?)，接著有一個比較簡潔的解法:

	:::C++
	void push(int n, elem* &&top);
	...

C++11 中兩個 & 即為 reference 的 reference，這樣就能傳 rvalue 了。
