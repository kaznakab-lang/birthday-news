/* お誕生日新聞 — 紙面の組み立て
   データ（作り置き）:
     data/years/YYYY.json   生まれ年の記事・コラム・物価・流行
     data/months/YYYY-MM.json 生まれ月の大ニュース・ほかの出来事
     data/days/MM-DD.json   月日特集・同じ誕生日の人・こよみ
   写真は Wikimedia Commons から表示時に取得（APIキー不要）。 */
(function () {
  'use strict';

  var MIN_YEAR = 1946, MAX_YEAR = 2008;
  var root = document.getElementById('root');
  var printBtn = document.getElementById('printBtn');

  // ---------- 小物 ----------
  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }
  function tpl(s, v) {
    return esc(s).replace(/\{(\w+)\}/g, function (m, k) { return k in v ? esc(v[k]) : m; });
  }
  function paras(list, v) {
    return (list || []).map(function (p, i) { return (i ? '　' : '') + tpl(p, v); }).join('<br>');
  }
  function num(n) { return n.toLocaleString('ja-JP'); }
  function pad(n) { return (n < 10 ? '0' : '') + n; }

  function wareki(y, m, d) {
    var t = y * 10000 + m * 100 + d;
    if (t >= 20190501) return '令和' + (y - 2018 === 1 ? '元' : y - 2018) + '年';
    if (t >= 19890108) return '平成' + (y - 1988 === 1 ? '元' : y - 1988) + '年';
    return '昭和' + (y - 1925) + '年';
  }
  var WEEK = ['日', '月', '火', '水', '木', '金', '土'];
  function zodiac(m, d) {
    var z = [[1, 20, 'やぎ座'], [2, 19, 'みずがめ座'], [3, 21, 'うお座'], [4, 20, 'おひつじ座'], [5, 21, 'おうし座'],
      [6, 22, 'ふたご座'], [7, 23, 'かに座'], [8, 23, 'しし座'], [9, 23, 'おとめ座'], [10, 24, 'てんびん座'],
      [11, 23, 'さそり座'], [12, 22, 'いて座'], [13, 1, 'やぎ座']];
    for (var i = 0; i < z.length; i++) if (m < z[i][0] || (m === z[i][0] && d < z[i][1])) return z[i][2];
    return 'やぎ座';
  }
  var STONE = ['', 'ガーネット', 'アメジスト', 'アクアマリン・コーラル', 'ダイヤモンド', 'エメラルド', 'パール・ムーンストーン',
    'ルビー', 'ペリドット', 'サファイア', 'オパール・トルマリン', 'トパーズ・シトリン', 'タンザナイト・ターコイズ・ラピスラズリ'];
  function season(m) {
    return m <= 2 || m === 12 ? '冬のさなか' : m <= 5 ? '春' : m <= 8 ? '夏' : '秋';
  }

  function getJSON(path) {
    return fetch(path, { cache: 'no-cache' }).then(function (r) {
      if (!r.ok) throw new Error('missing:' + path);
      return r.json();
    });
  }

  function showState(html) {
    root.innerHTML = '<div class="state">' + html + '<p><a href="./">入力にもどる</a></p></div>';
    printBtn.textContent = '印刷できません';
  }

  // ---------- 入力 ----------
  var q = new URLSearchParams(location.search);
  var dm = /^(\d{4})-(\d{2})-(\d{2})$/.exec(q.get('d') || '');
  if (!dm) { showState('<p>生年月日が指定されていません。</p>'); return; }
  var Y = +dm[1], M = +dm[2], D = +dm[3];
  var born = new Date(Y, M - 1, D);
  if (born.getMonth() !== M - 1 || Y < MIN_YEAR || Y > MAX_YEAR) {
    showState('<p>' + MIN_YEAR + '年〜' + MAX_YEAR + '年生まれの日付を入れてください。</p>'); return;
  }
  var name = (q.get('n') || '').trim().slice(0, 20) || 'あなた';
  var intro = (q.get('i') || '').trim().slice(0, 100);
  var message = (q.get('m') || '').trim().slice(0, 160);
  var from = (q.get('f') || '').trim().slice(0, 20);

  var today = new Date(); today.setHours(0, 0, 0, 0);
  var days = Math.round((today - born) / 86400000);
  // 迎える（迎えた）年齢：今年の誕生日から30日以内なら今年の年齢、それ以降は次の誕生日の年齢
  var bdThisYear = new Date(today.getFullYear(), M - 1, D);
  var age = today.getFullYear() - Y;
  if ((today - bdThisYear) / 86400000 > 30) age += 1;

  var V = { name: name, age: age, Y: Y, M: M, D: D, years: today.getFullYear() - Y };

  // ---------- 描画 ----------
  Promise.all([
    getJSON('data/years/' + Y + '.json'),
    getJSON('data/months/' + Y + '-' + pad(M) + '.json'),
    getJSON('data/days/' + pad(M) + '-' + pad(D) + '.json')
  ]).then(function (r) {
    render(r[0], r[1], r[2]);
    return loadPhotos();
  }).then(function () {
    fitAll();
    printBtn.disabled = false;
    printBtn.textContent = '印刷・PDF保存';
  }).catch(function (e) {
    console.error(e);
    showState('<p>この生年月日の紙面はただいま準備中です。<br>' + MIN_YEAR + '〜' + MAX_YEAR + '年生まれから、順次ふやしています。</p>');
  });

  function photo(spec, cls, label) {
    spec = spec || {};
    return '<div class="ph ' + (cls || '') + '" data-q="' + esc(spec.q || '') + '" data-file="' + esc(spec.file || '') +
      '" data-shape="' + esc(spec.shape || 'landscape') + '">' + esc(label || '') + '</div>';
  }

  function render(year, month, day) {
    var top = month.top;
    var kicker = top.day === D ? Y + '年' + M + '月' + D + '日のトップニュース' : Y + '年' + M + '月の大ニュース';
    var others = (month.others || []).slice().sort(function (a, b) {
      return Math.abs(a.day - D) - Math.abs(b.day - D);
    }).slice(0, 3).map(function (o) {
      return '◆' + (o.day === D ? '<b>この日</b>　' : M + '月' + o.day + '日　') + tpl(o.text, V);
    }).join('<br>');

    var topics = (year.topics || []).slice(0, 4).map(function (t) {
      return '<div class="topic">' + photo(t.photo, '', '') +
        '<div class="topic-text"><div class="topic-title"><span class="acc">' + esc(t.label) + '</span> ' + esc(t.title) + '</div>' +
        '<p class="body fit">' + paras(t.body, V) + '</p></div></div>';
    }).join('');

    var features = (day.features || []).slice(0, 3).map(function (f) {
      return '<div class="feature">' + photo(f.photo, '', '') +
        '<div class="feature-title"><span class="mincho acc">' + esc(f.year) + '年</span> ' + esc(f.title) + '</div>' +
        '<p class="body fit">' + paras(f.body, V) + '</p></div>';
    }).join('');

    var more = (day.more || []).map(function (m) {
      return '<span class="y">' + esc(m.year) + '</span><span>' + tpl(m.text, V) + '</span>';
    }).join('');

    var people = (day.people || []).slice(0, 4).map(function (p) {
      return '<div class="person">' + photo(Object.assign({ shape: 'portrait' }, p.photo), '', '') +
        '<div class="person-text"><span class="person-name">' + esc(p.name) + '（' + esc(p.born) + '年）</span>' +
        '<span class="person-bio fit">' + tpl(p.bio, V) + '</span></div></div>';
    }).join('');

    var prices = (year.prices || []).map(function (p) {
      return '<span>' + esc(p.item) + '</span><span>' + esc(p.then) + '</span><span>' + esc(p.now) + '</span>';
    }).join('');

    var trends = (year.trends || []).map(function (t) {
      return esc(t.k) + '：' + esc(t.v);
    }).join('<br>');

    var cal = day.calendar || {};
    var koyomi = [];
    if (cal.kinenbi) koyomi.push('記念日：' + esc(cal.kinenbi));
    if (cal.flower) koyomi.push('誕生花：' + esc(cal.flower));
    koyomi.push('誕生石：' + STONE[M]);
    koyomi.push('星座：' + zodiac(M, D));

    var yosete = season(M) + 'に、' + esc(name) + 'さんは生まれた。' + tpl(year.birthLine || '', V) +
      (intro ? '<br>　' + esc(intro) : '') +
      '<br>　' + age + '歳の一年が、笑顔あふれるものになりますように。';

    var msg = message
      ? '<p class="body msg"><b>お祝いの言葉</b>　' + esc(message) + (from ? '　—— ' + esc(from) + ' より' : '') + '</p>'
      : '';

    root.innerHTML =
      '<div class="sheet" id="sheet">' +
      // 題字
      '<div class="mast"><div class="daiji">誕生<br>日報</div><div class="mast-main">' +
      '<div class="mast-top"><span>第' + age + '号</span><span class="hb">HAPPY BIRTHDAY</span><span>' + esc(name) + ' 様 特別号</span></div>' +
      '<div class="mast-date">' + Y + '年（' + wareki(Y, M, D) + '）' + M + '月' + D + '日 ' + WEEK[born.getDay()] + '曜日</div>' +
      '<div class="mast-bottom"><span>あなたが生まれた日、世界ではこんなことが</span><span>生まれてから今日まで <b>' + num(days) + '</b> 日</span></div>' +
      '</div></div>' +
      // トップ
      '<div class="top"><div class="top-left">' + photo(top.photo, 'top-photo', '') +
      '<div class="caption">▲' + esc(top.photo && top.photo.caption || '') + '</div>' +
      (others ? '<div class="others body fit"><b>このほかの出来事</b><br>' + others + '</div>' : '') +
      '</div><div class="top-right">' +
      '<div class="kicker">' + kicker + '</div>' +
      '<h1 class="headline">' + esc(top.headline) + '<span class="sub">' + esc(top.sub || '') + '</span></h1>' +
      '<p class="lead">' + tpl(top.lead, V) + '</p>' +
      '<p class="body cols3 top-body fit">' + paras(top.body, V) + (top.note ? '<br>　<b>【解説】</b>' + tpl(top.note, V) : '') + '</p>' +
      '<h3 class="col-h">' + tpl(year.column.title, V) + '</h3>' +
      '<p class="body cols3 col-body">' + paras(year.column.body, V) + '</p>' +
      '</div></div>' +
      // 生まれ年
      '<div class="year"><h2 class="sec-h"><span>' + Y + '年はこんな年</span></h2><div class="year-grid">' + topics + '</div></div>' +
      // 月日特集
      '<div class="band"><div class="band-h"><span class="md">' + M + '月' + D + '日</span><span class="tok">特集</span><span class="note">歴史の中の、あなたの誕生日</span></div>' +
      '<div class="band-grid"><div class="features">' + features + '</div>' +
      '<div class="more"><h3>ほかにもこんな' + M + '月' + D + '日</h3><div class="more-list fit">' + more + '</div></div></div>' +
      '<div class="people-h">' + M + '月' + D + '日生まれの人</div><div class="people">' + people + '</div></div>' +
      // 下段
      '<div class="bottom">' +
      '<div class="cell"><h3>あの頃の物価</h3><div class="prices"><span></span><span class="h">当時</span><span class="h">いま</span>' + prices + '</div></div>' +
      '<div class="cell"><h3>流行・話題</h3><p class="small fit">' + trends + '</p></div>' +
      '<div class="cell"><h3>' + M + '月' + D + '日のこよみ</h3><p class="small">' + koyomi.join('<br>') + '</p></div>' +
      '<div class="cell last"><h3>誕生日によせて</h3><p class="body fit">' + yosete + '</p>' + msg + '</div>' +
      '</div>' +
      '<div class="foot"><span class="credits">写真：Wikimedia Commons（作者・ライセンスは各写真に表記）／出来事の出典：Wikipedia ほか</span>' +
      '<span class="issued">※記念品として作成　' + today.getFullYear() + '年' + (today.getMonth() + 1) + '月' + today.getDate() + '日 発行</span></div>' +
      '</div>';
    scale();
  }

  // ---------- 写真（Wikimedia Commons） ----------
  var API = 'https://commons.wikimedia.org/w/api.php?action=query&format=json&origin=*' +
    '&prop=imageinfo&iiprop=url|extmetadata|mime|size&iiurlwidth=1000';
  function okLicense(l) {
    l = (l || '').toLowerCase();
    if (/\bnc\b|non-?commercial|\bnd\b|no ?deriv|fair use/.test(l)) return false;
    return /^(cc0|public domain|pd|cc[- ]by)/.test(l);
  }
  function plain(html) {
    var d = document.createElement('div'); d.innerHTML = html || '';
    return (d.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 40);
  }
  function findPhoto(el) {
    var file = el.getAttribute('data-file'), qq = el.getAttribute('data-q');
    var shape = el.getAttribute('data-shape');
    if (!file && !qq) return Promise.resolve(null);
    var url = file ? API + '&titles=' + encodeURIComponent(file)
      : API + '&generator=search&gsrnamespace=6&gsrlimit=15&gsrsearch=' + encodeURIComponent(qq + ' filetype:bitmap');
    return fetch(url).then(function (r) { return r.json(); }).then(function (j) {
      var pages = Object.keys((j.query && j.query.pages) || {}).map(function (k) { return j.query.pages[k]; });
      pages.sort(function (a, b) { return (a.index || 0) - (b.index || 0); });
      var ok = pages.map(function (p) { return { p: p, ii: p.imageinfo && p.imageinfo[0] }; }).filter(function (x) {
        if (!x.ii || !/jpeg|png/.test(x.ii.mime) || x.ii.width < 400) return false;
        var md = x.ii.extmetadata || {};
        return okLicense(md.LicenseShortName && md.LicenseShortName.value);
      });
      var want = function (x) { var r = x.ii.width / x.ii.height; return shape === 'portrait' ? r < 1 : r >= 1.1; };
      var pick = ok.filter(want)[0] || ok[0];
      if (!pick) return null;
      var md = pick.ii.extmetadata || {};
      return {
        src: pick.ii.thumburl || pick.ii.url,
        credit: (plain(md.Artist && md.Artist.value) || '作者不明') + '／' + md.LicenseShortName.value
      };
    }).catch(function () { return null; });
  }
  function loadPhotos() {
    var els = Array.prototype.slice.call(document.querySelectorAll('.sheet .ph'));
    return Promise.all(els.map(function (el) {
      return findPhoto(el).then(function (ph) {
        if (!ph) { el.classList.add('none'); return; }
        var img = new Image();
        img.alt = '';
        img.referrerPolicy = 'no-referrer';
        img.src = ph.src;
        el.textContent = '';
        el.appendChild(img);
        var c = document.createElement('span');
        c.className = 'credit';
        c.textContent = ph.credit;
        el.appendChild(c);
        return (img.decode ? img.decode() : Promise.resolve()).catch(function () {});
      });
    }));
  }

  // ---------- はみ出し調整：収まるまで文字を少しずつ小さく ----------
  function fitAll() {
    document.querySelectorAll('.sheet .fit').forEach(function (el) {
      var size = parseFloat(getComputedStyle(el).fontSize), n = 0;
      while ((el.scrollHeight > el.clientHeight + 1 || el.scrollWidth > el.clientWidth + 1) && size > 8 && n < 30) {
        size -= 0.25; n++;
        el.style.fontSize = size + 'px';
      }
    });
  }

  // ---------- 画面幅に合わせて縮小表示 ----------
  function scale() {
    var s = Math.min(1, (window.innerWidth - 32) / 1123);
    var sc = document.getElementById('scaler');
    sc.style.transform = 'scale(' + s + ')';
    sc.style.width = 1123 * s + 'px';
    sc.style.height = 1587 * s + 'px';
  }
  window.addEventListener('resize', scale);

  printBtn.addEventListener('click', function () { window.print(); });
})();
