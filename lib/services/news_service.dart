/// News Service - Financial news and tips
class NewsService {
  /// Get latest financial news (mock data for hackathon)
  static List<NewsItem> getNews(String language) {
    final isHindi = language == 'hi';
    
    return [
      NewsItem(
        id: '1',
        title: isHindi ? 'पीएम किसान की 16वीं किस्त जल्द' : 'PM-KISAN 16th Installment Coming Soon',
        summary: isHindi 
            ? 'सरकार जल्द ही किसानों के खातों में ₹2,000 भेजेगी'
            : 'Government to transfer ₹2,000 to farmers\' accounts soon',
        category: 'schemes',
        imageEmoji: '🌾',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        isImportant: true,
      ),
      NewsItem(
        id: '2',
        title: isHindi ? 'जन धन खातों पर मिलेगा ₹10,000 ओवरड्राफ्ट' : 'Jan Dhan Accounts to Get ₹10,000 Overdraft',
        summary: isHindi 
            ? 'जीरो बैलेंस खातों पर भी मिलेगी यह सुविधा'
            : 'Zero balance accounts will also get this facility',
        category: 'banking',
        imageEmoji: '🏦',
        date: DateTime.now().subtract(const Duration(hours: 5)),
        isImportant: false,
      ),
      NewsItem(
        id: '3',
        title: isHindi ? 'सोने की कीमतों में गिरावट' : 'Gold Prices Drop',
        summary: isHindi 
            ? 'आज सोना ₹500 प्रति 10 ग्राम सस्ता हुआ'
            : 'Gold became cheaper by ₹500 per 10 grams today',
        category: 'market',
        imageEmoji: '💰',
        date: DateTime.now().subtract(const Duration(hours: 8)),
        isImportant: false,
      ),
      NewsItem(
        id: '4',
        title: isHindi ? 'मुद्रा लोन की सीमा बढ़ी' : 'Mudra Loan Limit Increased',
        summary: isHindi 
            ? 'अब ₹20 लाख तक का लोन बिना गारंटी के मिलेगा'
            : 'Now get up to ₹20 lakh loan without guarantee',
        category: 'schemes',
        imageEmoji: '💼',
        date: DateTime.now().subtract(const Duration(days: 1)),
        isImportant: true,
      ),
      NewsItem(
        id: '5',
        title: isHindi ? 'बचत खाते पर SBI का ब्याज बढ़ा' : 'SBI Increases Savings Account Interest',
        summary: isHindi 
            ? 'अब 2.75% से बढ़कर 3% ब्याज मिलेगा'
            : 'Interest rate increased from 2.75% to 3%',
        category: 'banking',
        imageEmoji: '📈',
        date: DateTime.now().subtract(const Duration(days: 1)),
        isImportant: false,
      ),
      NewsItem(
        id: '6',
        title: isHindi ? 'महिलाओं के लिए नई स्कीम' : 'New Scheme for Women',
        summary: isHindi 
            ? 'लखपति दीदी योजना में मिलेगी ₹1 लाख की मदद'
            : 'Lakhpati Didi scheme offers ₹1 lakh assistance',
        category: 'schemes',
        imageEmoji: '👩',
        date: DateTime.now().subtract(const Duration(days: 2)),
        isImportant: true,
      ),
    ];
  }

  /// Get news by category
  static List<NewsItem> getNewsByCategory(String category, String language) {
    return getNews(language).where((n) => n.category == category).toList();
  }

  /// Get important news
  static List<NewsItem> getImportantNews(String language) {
    return getNews(language).where((n) => n.isImportant).toList();
  }
}

class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String category;
  final String imageEmoji;
  final DateTime date;
  final bool isImportant;

  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.imageEmoji,
    required this.date,
    this.isImportant = false,
  });

  String getTimeAgo(bool isHindi) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) {
      return isHindi ? 'अभी' : 'Just now';
    } else if (diff.inHours < 24) {
      return isHindi ? '${diff.inHours} घंटे पहले' : '${diff.inHours}h ago';
    } else {
      return isHindi ? '${diff.inDays} दिन पहले' : '${diff.inDays}d ago';
    }
  }
}
