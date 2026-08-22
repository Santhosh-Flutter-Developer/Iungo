import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// Full policy text as shown in the reference screenshots/video, in both
/// English and Arabic (transcribed from the Arabic walkthrough video).
/// The page renders whichever matches the app's active locale — each
/// reads in its own natural direction (Arabic right-aligned/RTL, English
/// left-aligned/LTR), following the ambient [Directionality] GetX's
/// locale switch already sets for the whole app, so no manual override
/// is needed here.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _contactEmail = 'info@citgroupltd.com';

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.locale?.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        title: Text('privacy_statement'.tr, maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 40),
          children: isArabic ? _arabicContent() : _englishContent(),
        ),
      ),
    );
  }

  List<Widget> _englishContent() {
    return [
      const _Heading('Privacy and Information Confidentiality Policy'),
      _Paragraph.rich([
        const TextSpan(text: 'We at '),
        const TextSpan(
          text: 'CIT Limited',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const TextSpan(
          text: ' (the “Company”) appreciate your interest and concern '
              'over your data privacy on ',
        ),
        const TextSpan(
          text: 'Iungo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const TextSpan(text: ' (the “App”).'),
      ]),
      const _Paragraph(
        'This policy has been developed to support relevant users in '
        'understanding the nature of the data which the Company '
        'collects when they register through the App and use the App '
        'and how we handle such data.',
      ),
      const _Paragraph(
        'Given the importance of data and its confidentiality, and due '
        'to the Company’s efforts to provide the best level of '
        'services, the Company is committed to maintaining the privacy '
        'and confidentiality of users’ data and any other data entered '
        'by users. Such data may only be disclosed in accordance with '
        'approved law. The most important applied measure across the '
        'Company is to protect users\' personal information including:',
      ),
      const _Bullets([
        'Strict procedures to protect the information and technology '
            'used to prevent fraud and unauthorized access to our '
            'systems.',
        'Regular update of procedures and controls that meet or exceed '
            'standard criteria.',
        'The Company employees are highly trained and qualified to '
            'respect and protect the privacy and confidentiality of the '
            'App users\' personal information.',
        'The Company collects data, as per its statutes and authority, '
            'to the minimum limit required to fulfil the purposes of '
            'providing app services.',
      ]),
      const _Heading('Information we collect'),
      const _Paragraph(
        'The right to view users\' data and information shall be '
        'limited to the Company’s authorized employees and for the '
        'purposes and uses defined by the Company’s statutes.',
      ),
      const _Paragraph(
        'We may collect information about you when you use the App, '
        'including:',
      ),
      const _Bullets([
        'Device information: We may collect information about the '
            'device you are using, such as the model, operating system, '
            'and mobile network information.',
        'Usage information: We may collect information about how you '
            'use the App, such as the features you use, the content you '
            'view, and the actions you take.',
        'Location information: We may collect information about your '
            'geographical location if you enable location services on '
            'your device and use the App.',
        'Personal information: We may collect personal information '
            'used during account registration, such as your name, '
            'mobile number and email address, if you choose to provide '
            'it to us.',
        'Other information submitted by the user, such as Service '
            'Requests, Service Ratings and Customer Feedbacks.',
      ]),
      const _Heading('How we use your information'),
      const _Paragraph(
        'We may use the information we collect about you to:',
      ),
      const _Bullets([
        'Provide and improve the App: We use the information to '
            'operate and improve the App, including to develop new '
            'features and services.',
        'Personalize your experience: We may use the information to '
            'personalize your experience with the App, such as by '
            'recommending content or features that may be of interest '
            'to you.',
        'Communicate with you: We may use the information to '
            'communicate with you about the App, such as to send you '
            'updates or respond to your inquiries.',
        'Advertising and analytics: We may use the information to '
            'serve personalized advertising and to analyze how users '
            'interact with the App.',
        'Service Rating and Feedback: To enable you, at your option, to '
            'participate in interactive features of our services, rate '
            'our services as well as provide your feedback.',
        'Legal bases: For data processing in accordance with the '
            'Personal data protection law in the Kingdom of Saudi '
            'Arabia and of the General Data Protection Regulation '
            '(GDPR).',
      ]),
      const _Paragraph(
        'By submitting your data and personal information through the '
        'App, you completely agree that we store, process and use '
        'such data. We reserve the right at all times to disclose any '
        'information to the competent entities, as necessary, to '
        'comply with the law in the Kingdom of Saudi Arabia.',
      ),
      const _Heading('Data Protection Rights'),
      const _Paragraph('You have the following data protection rights:'),
      const _Bullets([
        'The right to access or update the information we have about '
            'you at any time: You have the right to access and update '
            'your information directly through your account settings '
            'section or you can request deletion of your personal '
            'information by contacting us.',
        'Right to rectification: You have the right to correct your '
            'information if the information is inaccurate or '
            'incomplete.',
        'Right to object: You have the right to object to our '
            'processing of your personal information.',
        'Right to restriction: You have the right to request us to '
            'restrict processing of your personal information.',
        'Right to data portability: You have the right to be provided '
            'with a copy of the information we hold about you in a '
            'structured, machine-readable and commonly used format.',
        'Right to withdraw consent: You have the right, at any time, '
            'to withdraw your consent on which we relied and processed '
            'your personal information.',
        'You have the right to complain to a data protection authority '
            'about our collection and use of your personal information, '
            'for more information please contact your local data '
            'protection authority.',
      ]),
      const _Paragraph(
        'We may ask you to verify your identity before responding to '
        'any such requests.',
      ),
      const _Heading('Retention of information:'),
      const _Paragraph(
        'We retain your personal information only for as long as it is '
        'necessary for the purposes set out in the Privacy Policy, to '
        'comply with our legal obligations (for example, if we are '
        'required to retain your data to comply with applicable laws), '
        'to resolve disputes, and to enforce our legal agreements and '
        'policies.',
      ),
      const _Paragraph(
        'We retain usage data for internal analytical and actionable '
        'purposes.',
      ),
      const _Paragraph(
        'In general, usage data is kept for a shorter period of time, '
        'except where the data is used to strengthen security and '
        'improve the functionality of our services and/or the App or '
        'where we are legally obligated to keep such data for a longer '
        'period.',
      ),
      const _Heading('Data Transformation:'),
      const _Paragraph(
        'Your information, including Personal Information, may be '
        'transferred and stored on computers located outside of your '
        'geographical area or other governmental jurisdiction where '
        'data protection laws differ from those of your jurisdiction.',
      ),
      const _Paragraph(
        'Your acceptance of this privacy policy and your provision of '
        'information accordingly constitutes your consent to transfer '
        'your data to any other country in which any of our '
        'subsidiaries and/or affiliates are located.',
      ),
      const _Paragraph(
        'We take all necessary measures to ensure that your data is '
        'treated securely and in accordance with this Privacy Policy '
        'as well as GDPR and that your personal data will not be '
        'transferred to any organization or country unless adequate '
        'controls are in place including the security of your data and '
        'other personal information.',
      ),
      const _Heading(
        'Disclosure in application of the provisions of the law:',
      ),
      const _Paragraph(
        'In certain circumstances, we may be required to disclose your '
        'personal information if required by law or to respond to '
        'requests from applicable Government authorities (e.g. a court '
        'or a government agency).',
      ),
      const _Paragraph(
        'We may disclose your personal information in good faith if '
        'such action is necessary to:',
      ),
      const _Bullets([
        'Enforce legal obligations.',
        'To protect and defend the rights of the Company and/or any of '
            'its subsidiaries and/or affiliate companies or any of its '
            'properties.',
        'To limit any wrongdoing related to the App.',
        'To protect the personal security of the App users.',
        'To protect against legal liability.',
      ]),
      const _Heading('Data Security'),
      const _Paragraph(
        'The security of your data is important to us, and we take '
        'reasonable measures to protect your information from '
        'unauthorized access, use, or disclosure. However, it must be '
        'remembered that transmission over the Internet and electronic '
        'storage methods are not 100% secure, so we cannot guarantee '
        'its absolute security.',
      ),
      const _Paragraph(
        'While we strive to use commercially acceptable means to '
        'protect your personal information, we do not guarantee that '
        'it is absolutely secure, as some events may occur outside our '
        'control and are not related to intentional behaviour and/or '
        'willful negligence on our part.',
      ),
      const _Heading('General Provisions'),
      const _Paragraph(
        'The Company reserves its right to carry out any minor or '
        'significant modifications to the policy from time to time, '
        'without any need for notification. Such modifications shall '
        'be valid from the time of publishing the same on the App. '
        'Your continued use of our App following such modifications '
        'shall be deemed an agreement to such modifications. '
        'Therefore, you shall regularly review the policy to make sure '
        'you are informed of its most recent version.',
      ),
      const _Paragraph(
        'Laws of the Kingdom of Saudi Arabia shall be the sole '
        'applicable laws in any conflict that might arise from using '
        'the App. Courts of Saudi Arabia shall have the sole '
        'jurisdiction over such conflicts.',
      ),
      const _Heading('Contact Us'),
      const _Paragraph(
        'Please contact us if you have any questions related to this '
        'privacy policy by e-mail at $_contactEmail.',
      ),
    ];
  }

  List<Widget> _arabicContent() {
    return [
      const _Heading('سياسة الخصوصية وسرية المعلومات'),
      const _Paragraph(
        'نحن في سي آي تي ليمتد ("الشركة") نقدر اهتمامكم وتساؤلاتكم '
        'بشأن خصوصية بياناتكم على إيونجو ("التطبيق").',
      ),
      const _Paragraph(
        'لقد تم تطوير هذه السياسة لدعم المستخدمين المعنيين في فهم '
        'طبيعة البيانات التي تجمعها الشركة عند التسجيل من خلال '
        'التطبيق واستخدام التطبيق وكيفية تعاملنا مع هذه البيانات.',
      ),
      const _Paragraph(
        'نظراً لأهمية البيانات وسريتها، وبسبب جهود الشركة لتقديم أفضل '
        'مستوى من الخدمات، تلتزم الشركة بالحفاظ على خصوصية وسرية '
        'بيانات المستخدمين وأي بيانات أخرى يدخلها المستخدمون. ولا '
        'يجوز الكشف عن هذه البيانات إلا وفقاً للقانون المعتمد. وإن من '
        'أهم الإجراءات التي يتم تطبيقها من خلال الشركة هو حماية '
        'المعلومات الشخصية للمستخدمين بما في ذلك:',
      ),
      const _Bullets([
        'الإجراءات الصارمة لحماية المعلومات والتكنولوجيا المستخدمة '
            'لمنع الاحتيال والوصول غير المصرح به إلى أنظمتنا.',
        'التحديث المنتظم للإجراءات والضوابط التي تلبي أو تتجاوز '
            'المعايير القياسية.',
        'إن موظفي الشركة مدربين تدريباً عالياً ومؤهلين لاحترام '
            'وحماية الخصوصية وسرية المعلومات الشخصية لمستخدمي '
            'التطبيق.',
        'تقوم الشركة بجمع البيانات وفقاً لأنظمتها الأساسية وسلطتها '
            'إلى الحد الأدنى المطلوب لتحقيق أغراض تقديم خدمات '
            'التطبيقات.',
      ]),
      const _Heading('المعلومات التي نقوم بجمعها'),
      const _Paragraph(
        'سيقتصر الحق في الاطلاع على بيانات المستخدمين ومعلوماتهم على '
        'موظفي الشركة المصرح لهم وللأغراض والاستخدامات المحددة في '
        'قوانين الشركة.',
      ),
      const _Paragraph(
        'قد نجمع معلومات عنك عند استخدامك للتطبيق، بما في ذلك:',
      ),
      const _Bullets([
        'معلومات الجهاز: قد نقوم بجمع معلومات حول الجهاز الذي '
            'تستخدمه، مثل الطراز ونظام التشغيل ومعلومات شبكة الهاتف '
            'المحمول.',
        'معلومات الاستخدام: قد نجمع معلومات حول كيفية استخدامك '
            'للتطبيق، مثل الميزات التي تستخدمها والمحتوى الذي تشاهده '
            'والإجراءات التي تتخذها.',
        'معلومات الموقع: قد نقوم بجمع معلومات حول موقعك الجغرافي في '
            'حال قمت بتمكين خدمات الموقع على جهازك واستخدمت '
            'التطبيق.',
        'المعلومات الشخصية: قد نقوم بجمع المعلومات الشخصية المستخدمة '
            'أثناء تسجيل الحساب، مثل اسمك ورقم هاتفك المحمول وعنوان '
            'بريدك الإلكتروني، في حال اخترت تزويدنا بها.',
        'المعلومات الأخرى المقدمة من المستخدم، مثل طلبات الخدمة '
            'وتقييمات الخدمة وتعليقات العملاء.',
      ]),
      const _Heading('كيف نقوم باستخدام معلوماتك'),
      const _Paragraph('قد نستخدم المعلومات التي نجمعها عنك من أجل:'),
      const _Bullets([
        'توفير التطبيق وتحسينه: نستخدم المعلومات لتشغيل التطبيق '
            'وتحسينه، بما في ذلك تطوير ميزات وخدمات جديدة.',
        'إضفاء الطابع الشخصي على تجربتك: قد نستخدم المعلومات لإضفاء '
            'الطابع الشخصي على تجربتك مع التطبيق، مثل التوصية '
            'بالمحتوى أو الميزات التي قد تهمك.',
        'التواصل معك: قد نستخدم المعلومات للتواصل معك بشأن التطبيق، '
            'مثل إرسال تحديثات إليك أو الرد على استفساراتك.',
        'الإعلانات والتحليلات: قد نستخدم المعلومات لخدمة الإعلانات '
            'المخصصة ولتحليل كيفية تفاعل المستخدمين مع التطبيق.',
        'تقييم الخدمة والملاحظات: لتمكينك من المشاركة في الميزات '
            'التفاعلية لخدماتنا حسب اختيارك، قم بتقييم خدماتنا وكذلك '
            'تقديم ملاحظاتك.',
        'الأسس القانونية: لمعالجة البيانات وفقاً لقانون حماية '
            'البيانات الشخصية في المملكة العربية السعودية ولائحة '
            'حماية البيانات العامة (GDPR).',
      ]),
      const _Paragraph(
        'من خلال تقديم بياناتك ومعلوماتك الشخصية من خلال التطبيق، '
        'فإنك توافق تماماً على أننا نقوم بتخزين ومعالجة واستخدام هذه '
        'البيانات. ونحتفظ بالحق في جميع الأوقات في الكشف عن أي '
        'معلومات للجهات المختصة، حسب الضرورة، للامتثال للقانون في '
        'المملكة العربية السعودية.',
      ),
      const _Heading('حقوق حماية البيانات'),
      const _Paragraph('لديك حقوق حماية البيانات التالية:'),
      const _Bullets([
        'الحق في الوصول إلى المعلومات التي لدينا عنك أو تحديثها في '
            'أي وقت: يحق لك الوصول إلى معلوماتك وتحديثها مباشرةً من '
            'خلال قسم إعدادات حسابك أو يمكنك طلب حذف معلوماتك '
            'الشخصية عن طريق الاتصال بنا.',
        'الحق في التصحيح: سيكون لك الحق في تصحيح المعلومات الخاصة '
            'بك في حال كانت المعلومات غير دقيقة أو غير كاملة.',
        'الحق في الاعتراض: يحق لك الاعتراض على معالجتنا لمعلوماتك '
            'الشخصية.',
        'حق التقييد: يحق لك أن تطلب منا أن تقييد معالجة معلوماتك '
            'الشخصية.',
        'الحق في نقل البيانات: يحق لك الحصول على نسخة من المعلومات '
            'التي نحتفظ بها عنك بتنسيق منظم ومقروء آلياً وشائع '
            'الاستخدام.',
        'الحق في سحب الموافقة: يحق لك في أي وقت سحب موافقتك التي '
            'اعتمدنا عليها ومعالجتنا لمعلوماتك الشخصية.',
        'لديك الحق في تقديم شكوى إلى سلطة حماية البيانات الشخصية '
            'حول جمعنا لمعلوماتك واستخدامها، لمزيد من المعلومات، '
            'يرجى الاتصال بهيئة حماية البيانات المحلية.',
      ]),
      const _Paragraph(
        'قد نطلب منك التحقق من هويتك قبل الرد على أي من هذه الطلبات.',
      ),
      const _Heading('الاحتفاظ بالمعلومات:'),
      const _Paragraph(
        'سنحتفظ بمعلوماتك الشخصية فقط طالما كانت ضرورية للأغراض '
        'المنصوص عليها في سياسة الخصوصية، وللامتثال لالتزاماتنا '
        'القانونية (على سبيل المثال، في حال كنا مطالبين بالاحتفاظ '
        'ببياناتك للامتثال للقوانين المعمول بها)، ولحل المنازعات، '
        'وتنفيذ اتفاقياتنا وسياساتنا القانونية.',
      ),
      const _Paragraph(
        'سنحتفظ ببيانات الاستخدام لأغراض تحليلية داخلية وقابلة '
        'للتنفيذ.',
      ),
      const _Paragraph(
        'بشكل عام، سيتم الاحتفاظ ببيانات الاستخدام لفترة زمنية أقصر '
        'باستثناء الحالات التي يتم فيها استخدام البيانات لتعزيز '
        'الأمان وتحسين وظائف خدماتنا و/أو التطبيق أو عندما نكون '
        'ملزمين قانوناً بالاحتفاظ بهذه البيانات لفترة أطول.',
      ),
      const _Heading('نقل البيانات:'),
      const _Paragraph(
        'قد يتم نقل معلوماتك بما في ذلك المعلومات الشخصية وتخزينها '
        'على أجهزة حاسب موجودة خارج منطقتك الجغرافية أو أي ولاية '
        'قضائية حكومية أخرى حيث تختلف قوانين حماية البيانات عن تلك '
        'الخاصة بولايتك القضائية.',
      ),
      const _Paragraph(
        'يشكل قبولك لسياسة الخصوصية هذه وتقديمك المعلومات وفقاً '
        'لذلك موافقتك على نقل بياناتك إلى أي دولة أخرى توجد فيها أي '
        'من الشركات التابعة و/أو الشركات الشقيقة لنا.',
      ),
      const _Paragraph(
        'سنتخذ جميع التدابير اللازمة لضمان التعامل مع بياناتك بشكل '
        'آمن ووفقاً لسياسة الخصوصية هذه بالإضافة إلى القانون العام '
        'لحماية البيانات وأن بياناتك الشخصية لن يتم نقلها إلى أي '
        'دولة أو منظمة ما لم يتم وضع ضوابط كافية بما في ذلك أمان '
        'بياناتك وغيرها من المعلومات الشخصية.',
      ),
      const _Heading('الإفصاح تطبيقاً لأحكام القانون:'),
      const _Paragraph(
        'قد يُطلب منا في ظروف معينة الكشف عن معلوماتك الشخصية في '
        'حال كان ذلك مطلوباً بموجب القانون أو الاستجابة لطلبات من '
        'السلطات الحكومية المعمول بها (مثل محكمة أو وكالة حكومية).',
      ),
      const _Paragraph(
        'قد نكشف عن معلوماتك الشخصية بحسن نية إذا كان هذا الإجراء '
        'ضرورياً من أجل:',
      ),
      const _Bullets([
        'تنفيذ الالتزامات القانونية.',
        'حماية والدفاع عن حقوق الشركة و/أو أي من الشركات التابعة '
            'و/أو الشركات الشقيقة لها أو أي من ممتلكاتها.',
        'الحد من أي مخالفات تتعلق بالتطبيق.',
        'حماية الأمن الشخصي لمستخدمي التطبيق.',
        'الحماية من المسؤولية القانونية.',
      ]),
      const _Heading('أمن البيانات'),
      const _Paragraph(
        'يعد أمان بياناتك أمراً مهماً بالنسبة لنا، وسنتخذ إجراءات '
        'معقولة لحماية معلوماتك من الوصول أو الاستخدام أو الكشف غير '
        'المصرح به، وبالرغم من ذلك، يجب أن نذكر أن النقل عبر '
        'الإنترنت وطرق التخزين الإلكترونية ليست آمنة بنسبة 100%، '
        'لذلك لا يمكننا ضمان أمانها المطلق.',
      ),
      const _Paragraph(
        'بينما نسعى جاهدين لاستخدام وسائل مقبولة تجارياً لحماية '
        'معلوماتك الشخصية، فإننا لا نضمن أنها آمنة تماماً، حيث قد '
        'تحدث بعض الأحداث خارج سيطرتنا ولا تتعلق بالسلوك المتعمد '
        'و/أو الإهمال المتعمد من جانبنا.',
      ),
      const _Heading('الأحكام العامة'),
      const _Paragraph(
        'تحتفظ الشركة بحقها في إجراء أي تعديلات طفيفة أو مهمة على '
        'السياسة من وقت لآخر، دون الحاجة إلى إخطار. وستكون هذه '
        'التعديلات صالحة من وقت نشرها على التطبيق. ويعتبر استمرار '
        'استخدامك لتطبيقنا بعد هذه التعديلات بمثابة موافقة على هذه '
        'التعديلات. وبناءً على ذلك، يجب عليك مراجعة السياسة '
        'بانتظام للتأكد من اطلاعك على أحدث إصدار لها.',
      ),
      const _Paragraph(
        'ستكون قوانين المملكة العربية السعودية هي القوانين الوحيدة '
        'المعمول بها في أي نزاع قد ينشأ عن استخدام التطبيق. وسيكون '
        'لمحاكم المملكة العربية السعودية الاختصاص الوحيد في فض مثل '
        'هذه المنازعات.',
      ),
      const _Heading('اتصل بنا'),
      const _Paragraph(
        'يرجى الاتصال بنا في حال كانت لديك أي استفسارات تتعلق '
        'بسياسة الخصوصية هذه عن طريق البريد الإلكتروني على '
        '$_contactEmail.',
      ),
    ];
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 18),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
          height: 1.25,
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text) : spans = null;

  const _Paragraph.rich(List<InlineSpan> spans)
      : text = null,
        spans = spans;

  final String? text;
  final List<InlineSpan>? spans;

  static const _style = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: spans != null
          ? Text.rich(
              TextSpan(style: _style, children: spans),
              textAlign: TextAlign.start,
            )
          : Text(text!, style: _style, textAlign: TextAlign.start),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      '•  ',
                      style: TextStyle(
                        fontSize: 17,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: _Paragraph._style,
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}