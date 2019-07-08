#ifndef EDIT_UTILS_H
#define EDIT_UTILS_H

#include <QObject>

#include "markdown.h"
#include "html.h"
#include "buffer.h"


class EditUtils : public QObject{
   Q_OBJECT
public:
    explicit EditUtils (QObject* parent = 0) : QObject(parent) {}
    Q_INVOKABLE QString markdown(QString input){
        struct sd_callbacks callbacks;
        struct html_renderopt options;
        struct sd_markdown *markdown;

        struct buf* ob;
        ob = bufnew(64);
        sdhtml_renderer(&callbacks, &options, 0);
        markdown = sd_markdown_new(0, 16, &callbacks, &options);

        sd_markdown_render(ob, (const unsigned char*)input.toUtf8().constData(), input.toUtf8().length(), markdown);
        sd_markdown_free(markdown);

        QString ret = QString(bufcstr(ob));
        bufrelease(ob);
        return ret;
    }
};

#endif // EDIT_UTILS_H
