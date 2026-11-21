const menu = document.querySelector('.menu');
const nav = document.querySelector('.nav');

function setMenu(open) {
  nav.classList.toggle('open', open);
  menu.setAttribute('aria-expanded', String(open));
  menu.setAttribute('aria-label', open ? 'Закрыть меню' : 'Открыть меню');
  menu.firstElementChild.textContent = open ? '×' : '☰';
}

menu.addEventListener('click', () => setMenu(!nav.classList.contains('open')));
nav.addEventListener('click', event => {
  if (event.target.closest('a')) setMenu(false);
});
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && nav.classList.contains('open')) {
    setMenu(false);
    menu.focus();
  }
});

const cases = document.querySelector('.case-track');
document.querySelector('.case-next').addEventListener('click', () => {
  const firstCard = cases.firstElementChild;
  const step = firstCard.nextElementSibling.offsetLeft - firstCard.offsetLeft;
  const atEnd = cases.scrollLeft + cases.clientWidth >= cases.scrollWidth - 2;
  cases.scrollTo({ left: atEnd ? 0 : cases.scrollLeft + step });
});

const contact = document.querySelector('.contact-form');
const contactStatus = document.querySelector('.contact-status');
contact.addEventListener('submit', async event => {
  event.preventDefault();
  const form = new FormData(contact);
  const draft = [
    `Имя: ${form.get('name')}`,
    `Способ связи: ${form.get('method')}`,
    `Контакт: ${form.get('reply')}`,
    form.get('comment') && `Комментарий: ${form.get('comment')}`
  ].filter(Boolean).join('\n');

  try {
    await navigator.clipboard.writeText(draft);
    contactStatus.textContent = 'Заявка скопирована. Вставьте её в сообщение в Telegram.';
  } catch {
    contactStatus.textContent = 'Копирование недоступно. Откройте Telegram и введите данные в сообщении.';
  }
  contactStatus.hidden = false;
});
