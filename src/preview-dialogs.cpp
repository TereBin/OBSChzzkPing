#include "preview-dialogs.hpp"

#include <QDialog>
#include <QDialogButtonBox>
#include <QFrame>
#include <QHBoxLayout>
#include <QJsonArray>
#include <QJsonObject>
#include <QLabel>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QScrollArea>
#include <QString>
#include <QVBoxLayout>

namespace
{
QDialogButtonBox *createCloseButtons(QDialog *dialog)
{
  auto *buttons = new QDialogButtonBox(QDialogButtonBox::Close, dialog);
  buttons->button(QDialogButtonBox::Close)->setText(QStringLiteral("닫기"));
  QObject::connect(buttons, &QDialogButtonBox::rejected, dialog, &QDialog::reject);
  return buttons;
}

QLabel *createSelectableLabel(const QString &text, QWidget *parent)
{
  auto *label = new QLabel(text, parent);
  label->setTextFormat(Qt::PlainText);
  label->setTextInteractionFlags(Qt::TextSelectableByMouse);
  label->setWordWrap(true);
  return label;
}
} // namespace

void showDiscordPreviewDialog(QWidget *parent, const QJsonObject &payload, bool usedFallback)
{
  QDialog dialog(parent);
  dialog.setWindowTitle(QStringLiteral("Discord 메시지 미리보기"));
  dialog.resize(620, 520);

  auto *previewContent = new QWidget(&dialog);
  auto *previewLayout = new QVBoxLayout(previewContent);
  previewLayout->setContentsMargins(18, 18, 18, 18);
  previewLayout->setSpacing(10);

  auto *authorLabel = new QLabel(QStringLiteral("StreamPing"), previewContent);
  authorLabel->setStyleSheet(QStringLiteral("font-weight: 600;"));
  previewLayout->addWidget(authorLabel);
  previewLayout->addWidget(
      createSelectableLabel(payload.value(QStringLiteral("content")).toString(), previewContent));

  const QJsonObject embed = payload.value(QStringLiteral("embeds")).toArray().first().toObject();
  auto *embedFrame = new QFrame(previewContent);
  embedFrame->setObjectName(QStringLiteral("discordEmbed"));
  embedFrame->setStyleSheet(
      QStringLiteral("QFrame#discordEmbed { background: #2b2d31; border-radius: 4px; }"
                     "QFrame#discordEmbed QLabel { color: #dbdee1; }"));

  auto *embedLayout = new QHBoxLayout(embedFrame);
  embedLayout->setContentsMargins(0, 0, 12, 0);
  embedLayout->setSpacing(12);

  const int color = embed.value(QStringLiteral("color")).toInt() & 0xffffff;
  auto *colorStrip = new QWidget(embedFrame);
  colorStrip->setFixedWidth(5);
  colorStrip->setStyleSheet(
      QStringLiteral("background: #%1; border-radius: 2px;").arg(color, 6, 16, QLatin1Char('0')));
  embedLayout->addWidget(colorStrip);

  auto *embedDetails = new QVBoxLayout;
  embedDetails->setContentsMargins(0, 12, 0, 12);
  embedDetails->setSpacing(10);

  auto *titleLabel =
      createSelectableLabel(embed.value(QStringLiteral("title")).toString(), embedFrame);
  titleLabel->setStyleSheet(QStringLiteral("color: #00a8fc; font-weight: 600;"));
  embedDetails->addWidget(titleLabel);

  const QJsonArray fields = embed.value(QStringLiteral("fields")).toArray();
  if (!fields.isEmpty())
  {
    auto *fieldsLayout = new QHBoxLayout;
    fieldsLayout->setSpacing(24);
    for (const QJsonValue &value : fields)
    {
      const QJsonObject field = value.toObject();
      auto *fieldLayout = new QVBoxLayout;
      fieldLayout->setSpacing(3);
      auto *nameLabel = new QLabel(field.value(QStringLiteral("name")).toString(), embedFrame);
      nameLabel->setStyleSheet(QStringLiteral("font-weight: 600;"));
      fieldLayout->addWidget(nameLabel);
      fieldLayout->addWidget(
          createSelectableLabel(field.value(QStringLiteral("value")).toString(), embedFrame));
      fieldsLayout->addLayout(fieldLayout, 1);
    }
    embedDetails->addLayout(fieldsLayout);
  }
  embedLayout->addLayout(embedDetails, 1);

  if (embed.contains(QStringLiteral("image")))
  {
    auto *thumbnailLabel = new QLabel(QStringLiteral("LIVE\n썸네일"), embedFrame);
    thumbnailLabel->setAlignment(Qt::AlignCenter);
    thumbnailLabel->setFixedSize(96, 72);
    thumbnailLabel->setStyleSheet(QStringLiteral(
        "background: #1e1f22; border: 1px solid #3f4147; border-radius: 4px; color: #b5bac1;"));
    embedLayout->addWidget(thumbnailLabel, 0, Qt::AlignTop);
  }

  previewLayout->addWidget(embedFrame);
  if (usedFallback)
  {
    auto *fallbackLabel = new QLabel(
        QStringLiteral("치지직 조회에 실패하거나 방송 정보가 없어 예시 값을 사용했습니다."),
        previewContent);
    fallbackLabel->setWordWrap(true);
    fallbackLabel->setStyleSheet(QStringLiteral("color: #f0b232;"));
    previewLayout->addWidget(fallbackLabel);
  }
  previewLayout->addStretch();

  auto *scrollArea = new QScrollArea(&dialog);
  scrollArea->setWidgetResizable(true);
  scrollArea->setFrameShape(QFrame::NoFrame);
  scrollArea->setWidget(previewContent);

  auto *layout = new QVBoxLayout(&dialog);
  layout->addWidget(scrollArea, 1);
  layout->addWidget(createCloseButtons(&dialog));
  dialog.exec();
}

void showTextPreviewDialog(QWidget *parent, const QString &title, const QString &text)
{
  QDialog dialog(parent);
  dialog.setWindowTitle(title);
  dialog.resize(520, 420);
  auto *editor = new QPlainTextEdit(text, &dialog);
  editor->setReadOnly(true);
  auto *layout = new QVBoxLayout(&dialog);
  layout->addWidget(editor);
  layout->addWidget(createCloseButtons(&dialog));
  dialog.exec();
}
