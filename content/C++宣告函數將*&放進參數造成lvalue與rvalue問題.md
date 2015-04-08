Title: C++ 函數參數Reference跟指標混用造成的lvalue跟rvalue問題
Date: 2015-04-08 15:30
Category: 語言
Tags: C++

某次在寫stack題時出現的code，因為題目中pop stack A時必定會push一元素進stack A，然後我很無聊的想把pop跟push一起解決因此出現下面的code:

宣告的部份，一個stack由一堆elem構成，
用最上面的elem作為top代表一個stack，
因為top會變動故Call by reference。
因為題目有如上性質令pop時會回傳新的top。

	:::C++
	void push(int n, elem* &top);
	elem* pop(elem* &top);

依據題目性質，stack A pop時直接將新元素push進stack A:

	:::C++
	push(n, pop(A));

這時就噴錯了，登登！

	:::text
	error: invalid initialization of non-const reference of type ‘elem*&’ from an rvalue of type ‘elem*’

阿，原來是call by reference時不能丟rvalue的reference當parameter，因為這樣rvalue的值可能會被直接變動
這好像是常識...Orz
那應該有兩個解決辦法：

1.  分開寫就好(不要罵我髒話(つд⊂))，不過只是因為這個狀況函數其實不需要回傳東西，其他狀況的話應該要存到暫時變數：

		:::C++
		pop(A);
		push(n, A);
		//work!!
		
   		elem* tmp = pop(A);
		push(n, tmp);
		//一般情形，就是pop回傳的東西才是重點的情況

2.  宣告時加const使reference不能被變動:

		:::C++
		void push(elem* const &n, elem* &top);
		
		...
		
		push(pop(A), B);

又噴錯了QAQ：

	:::text nowrap
	error: invalid initialization of non-const reference of type ‘const elem*&’ from an rvalue of type ‘elem*’

恩...簡單來說這樣好像是被判斷成「一個const的elem指標」的reference，但是reference依舊不是const，所以要這樣解決：

	:::C++
	void push(int n, elem* const &top);

這樣top才會被視為一個const的「elem指標的reference」。

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
	//work!!

終於成功了QAQ，不過這些好像大部份是常識(?)，接著有一個神祕解法:

	:::C++
	void push(int n, elem* &&top);
	...

C++11的用法，再加一個&變成reference的reference(怎麼感覺比pointer to pointer邪門不少...)，這樣就能傳rvalue了

心得：

1.  *跟&混用還是挺有趣而且挺方便的...可是要注意很多lvalue跟rvalue的事情Orz
2.  C++好難阿

以上感謝FB上的各路大神出手相助XD
